#!/usr/bin/env python
import locale
from datetime import datetime, timedelta
from bs4 import BeautifulSoup
from icalendar import Calendar, Event
import pytz
import requests
import sys
import math

# Set locale to Dutch
try:
    locale.setlocale(locale.LC_TIME, 'nl_NL.UTF-8')
except locale.Error:
    try:
        locale.setlocale(locale.LC_TIME, 'nl_NL')
    except locale.Error:
        print("Warning: Could not set locale to nl_NL.UTF-8 or nl_NL. Using default.", file=sys.stderr)


# Fetch the HTML content
url = "https://hipsy.nl/shop/play-nijmegen"
try:
    response = requests.get(url, timeout=15)
    response.raise_for_status() # Raise an exception for bad status codes
    html_content = response.text
except requests.exceptions.RequestException as e:
    print(f"Error fetching URL {url}: {e}", file=sys.stderr)
    sys.exit(1)


# Parse the HTML
soup = BeautifulSoup(html_content, 'html.parser')

# Create a calendar
cal = Calendar()
cal.add('prodid', '-//Play Nijmegen Events//hipsy.nl//')
cal.add('version', '2.0')
cal.add('X-WR-CALNAME', 'Play Nijmegen Events') # Add Calendar Name
cal.add('X-WR-TIMEZONE', 'Europe/Amsterdam') # Add Timezone

# Set timezone
amsterdam_tz = pytz.timezone('Europe/Amsterdam')

# Find all event divs - updated selector to match current structure
event_divs = soup.find_all('div', class_='bg-white py-4 md:py-0 w-full rounded-lg md:rounded-bl-3xl overflow-hidden flex shadow-xs cursor-pointer relative')

total_events_added = 0

for event_div in event_divs:

    # Extract event details with updated selectors
    title_elem = event_div.find('a', class_='text-xl')
    if not title_elem:
        print("Skipping div, title element not found.", file=sys.stderr)
        continue

    title = title_elem.text.strip()

    # Extract description
    description_elem = event_div.find('p', class_='text-sm text-gray-800 py-2')
    description = description_elem.text.strip() if description_elem else "No description available"

    # Extract date string
    date_elem = event_div.find('div', class_='text-primary text-sm md:font-bold')
    if not date_elem:
        print(f"Skipping event '{title}', date element not found.", file=sys.stderr)
        continue

    date_str = date_elem.text.strip()

    # Extract the event URL
    event_url = title_elem.get('href')
    if not event_url:
         print(f"Skipping event '{title}', URL not found in title element.", file=sys.stderr)
         continue
    if not event_url.startswith('http'):
        event_url = "https://hipsy.nl" + event_url

    # Extract and store categories/tags if available - needed for recurring events too
    tags = []
    tag_elems = event_div.find_all('span', class_='bg-secondary-light rounded-sm md:rounded-full text-xs md:font-bold text-primary py-0.5 px-1.5 md:px-2.5 md:py-1 whitespace-nowrap')
    if tag_elems:
        for tag_elem in tag_elems:
            tags.append(tag_elem.text.strip())

    # Parse date and time
    try:
        start_date = None
        end_date = None

        if ' tot ' in date_str:
            parts = date_str.split(' tot ')
            start_str = parts[0].strip()
            end_str = parts[1].strip()

            if ' van ' in start_str:
                # Single day event with start and end times: "Woensdag 1 januari 2025 van 10:00 tot 12:00"
                date_part, times = start_str.split(' van ')
                start_time_str = times
                end_time_str = end_str # End time is just the second part after 'tot'
                start_date = datetime.strptime(f"{date_part} {start_time_str}", '%A %d %B %Y %H:%M')
                # Need to re-parse end_date with the *same* date part
                end_date = datetime.strptime(f"{date_part} {end_time_str}", '%A %d %B %Y %H:%M')
            else:
                # Multi-day event: "Dinsdag 06 mei 2025 om 19:15 tot dinsdag 27 mei 2025 om 22:00"
                # Or: "Vrijdag 06 juni 2025 om 17:00 tot maandag 09 juni 2025 om 15:00"
                # Or potentially just dates: "Maandag 1 jan 2025 tot Vrijdag 5 jan 2025"

                # Try formats with explicit time first
                try:
                    start_format = '%A %d %B %Y om %H:%M' if ' om ' in start_str else '%A %d %B %Y %H:%M'
                    end_format = '%A %d %B %Y om %H:%M' if ' om ' in end_str else '%A %d %B %Y %H:%M'
                    start_date = datetime.strptime(start_str, start_format)
                    end_date = datetime.strptime(end_str, end_format)
                except ValueError:
                     # If time parsing fails, try parsing as dates only
                    try:
                        start_date = datetime.strptime(start_str, '%A %d %B %Y')
                        end_date = datetime.strptime(end_str, '%A %d %B %Y')
                        # Set default times if only dates are provided (make it all day?)
                        # Or use sensible defaults like 9-5? Let's stick to 9-5 for now.
                        start_date = start_date.replace(hour=9, minute=0)
                        end_date = end_date.replace(hour=17, minute=0)
                        print(f"Warning: Parsed multi-day event '{title}' without specific times, assuming 09:00-17:00.", file=sys.stderr)
                    except ValueError as e_date:
                        print(f"Could not parse multi-day format for event: {title}", file=sys.stderr)
                        print(f"Date string: {date_str}", file=sys.stderr)
                        print(f"Error: {e_date}", file=sys.stderr)
                        continue # Skip this event if date parsing fails completely

        elif ' van ' in date_str:
            # Single day event with only start time: "Zondag 18 mei 2025 van 14:15" (implies end time is missing)
            date_part, start_time_str = date_str.split(' van ')
            start_date = datetime.strptime(f"{date_part} {start_time_str}", '%A %d %B %Y %H:%M')
            end_date = start_date + timedelta(hours=2)  # Assume 2-hour duration
            print(f"Warning: Event '{title}' only had start time, assuming 2-hour duration.", file=sys.stderr)
        elif ' vanaf ' in date_str:
            # Event with "vanaf" format: "Dinsdag 1 januari 2025 vanaf 19:00"
            start_date = datetime.strptime(date_str, '%A %d %B %Y vanaf %H:%M')
            end_date = start_date + timedelta(hours=2)  # Assume 2-hour duration
            print(f"Warning: Event '{title}' used 'vanaf', assuming 2-hour duration.", file=sys.stderr)
        elif ' om ' in date_str:
             # Event with "om" format, likely single day: "Woensdag 1 januari 2025 om 10:00"
            parts = date_str.split(' om ')
            date_part = parts[0]
            time_part = parts[1]
            start_date = datetime.strptime(f"{date_part} {time_part}", '%A %d %B %Y %H:%M')
            end_date = start_date + timedelta(hours=2)  # Assume 2-hour duration
            print(f"Warning: Event '{title}' used 'om', assuming 2-hour duration.", file=sys.stderr)
        else:
            # Fallback for unrecognized formats or maybe just a date?
            try:
                # Try parsing just as a date
                start_date = datetime.strptime(date_str, '%A %d %B %Y')
                # Make it an all-day event? Or default duration? Let's assume 2 hours from 9am.
                start_date = start_date.replace(hour=9, minute=0)
                end_date = start_date + timedelta(hours=2)
                print(f"Warning: Unrecognized date format for event '{title}', parsed as date only, assuming 09:00 + 2 hours.", file=sys.stderr)
            except ValueError:
                print(f"Unrecognized date format for event: {title}", file=sys.stderr)
                print(f"Date string: {date_str}", file=sys.stderr)
                continue

        # --- Check for Recurring Cursus ---
        is_cursus = 'cursus' in title.lower()
        # Check if it spans multiple days and end time is later than start time (on their respective days)
        is_multi_day = (end_date.date() - start_date.date()).days > 0
        # Ensure end time is strictly later than start time, implies it's not overnight spanning the day boundary
        # Or if start/end time are identical maybe? No, stick to strictly later.
        ends_later_same_day = end_date.time() > start_date.time()

        # Check if the total duration in days is an exact multiple of 7
        total_days_diff = (end_date.date() - start_date.date()).days
        is_multiple_of_7_days = total_days_diff > 0 and total_days_diff % 7 == 0

        if is_cursus and is_multi_day and ends_later_same_day and is_multiple_of_7_days:
            print(f"Detected recurring cursus: {title} from {start_date.date()} to {end_date.date()}", file=sys.stderr)
            num_weeks = (total_days_diff // 7) + 1
            # Calculate the duration of a single session
            # Use the time difference on the first day
            session_duration = end_date.replace(year=start_date.year, month=start_date.month, day=start_date.day) - start_date
            # Ensure duration is positive if it crosses midnight (unlikely for cursus but safe)
            if session_duration.total_seconds() < 0:
                 session_duration += timedelta(days=1) # Should not happen based on ends_later_same_day check

            print(f"  Generating {num_weeks} recurring events with duration {session_duration}", file=sys.stderr)

            for i in range(num_weeks):
                recurring_event = Event()
                current_start_date_naive = start_date + timedelta(weeks=i)
                current_end_date_naive = current_start_date_naive + session_duration

                # Localize dates
                current_start_date_aware = amsterdam_tz.localize(current_start_date_naive)
                current_end_date_aware = amsterdam_tz.localize(current_end_date_naive)

                # Add event details to the calendar
                recurring_event.add('summary', f"{title} (Week {i+1}/{num_weeks})")
                recurring_event.add('description', f"{description}\n\n(Part {i+1} of {num_weeks})\n\nMore info: {event_url}")
                recurring_event.add('dtstart', current_start_date_aware)
                recurring_event.add('dtend', current_end_date_aware)
                recurring_event.add('dtstamp', amsterdam_tz.localize(datetime.now())) # Add timestamp of creation
                recurring_event.add('uid', f"{event_url.split('/')[-1]}-week{i+1}@{url.split('/')[2]}") # Unique ID per instance
                recurring_event.add('url', event_url)

                if tags:
                    recurring_event.add('categories', tags)

                cal.add_component(recurring_event)
                total_events_added += 1
            # Skip adding the original single multi-week event
            continue

        # --- Handle Non-Recurring Events (or those not matching the criteria) ---
        event = Event()

        # Localize dates
        start_date_aware = amsterdam_tz.localize(start_date)
        end_date_aware = amsterdam_tz.localize(end_date)

        # Add event details to the calendar
        event.add('summary', title)
        event.add('description', f"{description}\n\nMore info: {event_url}")
        event.add('dtstart', start_date_aware)
        event.add('dtend', end_date_aware)
        event.add('dtstamp', amsterdam_tz.localize(datetime.now())) # Add timestamp of creation
        event.add('uid', f"{event_url.split('/')[-1]}@{url.split('/')[2]}") # Unique ID
        event.add('url', event_url)

        if tags:
            event.add('categories', tags)

        cal.add_component(event)
        total_events_added += 1

    except ValueError as e:
        print(f"Could not parse date for event: {title}", file=sys.stderr)
        print(f"Error: {e}", file=sys.stderr)
        print(f"Date string: {date_str}", file=sys.stderr)
        # Continue with the next event instead of stopping
    except Exception as ex:
        print(f"An unexpected error occurred processing event: {title}", file=sys.stderr)
        print(f"Error: {ex}", file=sys.stderr)
        print(f"Date string: {date_str}", file=sys.stderr)
        continue


# Generate iCal content
try:
    ical_content = cal.to_ical()
except Exception as e:
    print(f"Error generating iCal content: {e}", file=sys.stderr)
    sys.exit(1)

def main(file_name='play_nijmegen_events.ics'):
    # Save to file
    try:
        with open(file_name, 'wb') as f:
            f.write(ical_content)
        # Use total_events_added instead of len(cal.subcomponents) as it reflects generated events accurately
        print(f"iCal file '{file_name}' has been created with {total_events_added} events.")
    except IOError as e:
        print(f"Error writing iCal file '{file_name}': {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    output_file = 'play_nijmegen_events.ics'
    if len(sys.argv) == 2:
        output_file = sys.argv[1]
    elif len(sys.argv) > 2:
        print("Usage: python script_name.py [output_filename.ics]", file=sys.stderr)
        sys.exit(1)
    main(output_file)
