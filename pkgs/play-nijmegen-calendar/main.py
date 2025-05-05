#!/usr/bin/env python
import locale
from datetime import datetime, timedelta
from bs4 import BeautifulSoup
from icalendar import Calendar, Event
import pytz
import requests
import sys

# Set locale to Dutch
locale.setlocale(locale.LC_TIME, 'nl_NL.UTF-8')

# Fetch the HTML content
url = "https://hipsy.nl/shop/play-nijmegen"
response = requests.get(url)
html_content = response.text

# Parse the HTML
soup = BeautifulSoup(html_content, 'html.parser')

# Create a calendar
cal = Calendar()
cal.add('prodid', '-//Play Nijmegen Events//hipsy.nl//')
cal.add('version', '2.0')

# Find all event divs - updated selector to match current structure
event_divs = soup.find_all('div', class_='bg-white py-4 md:py-0 w-full rounded-lg md:rounded-bl-3xl overflow-hidden flex shadow-xs cursor-pointer relative')

for event_div in event_divs:
    event = Event()

    # Extract event details with updated selectors
    title_elem = event_div.find('a', class_='text-xl')
    if not title_elem:
        continue

    title = title_elem.text.strip()

    # Extract description
    description_elem = event_div.find('p', class_='text-sm text-gray-800 py-2')
    description = description_elem.text.strip() if description_elem else "No description available"

    # Extract date string
    date_elem = event_div.find('div', class_='text-green text-sm md:font-bold')
    if not date_elem:
        continue

    date_str = date_elem.text.strip()

    # Extract the event URL
    event_url = title_elem['href']
    if not event_url.startswith('http'):
        event_url = "https://hipsy.nl" + event_url

    # Parse date and time
    try:
        if ' tot ' in date_str:
            if ' van ' in date_str:
                # Single day event with start and end times
                date, times = date_str.split(' van ')
                start_time, end_time = times.split(' tot ')
                start_date = datetime.strptime(f"{date} {start_time}", '%A %d %B %Y %H:%M')
                end_date = datetime.strptime(f"{date} {end_time}", '%A %d %B %Y %H:%M')
            else:
                # Multi-day event (handle both formats)
                parts = date_str.split(' tot ')
                if len(parts) == 2:
                    start_str, end_str = parts

                    # Check if it has "om" format
                    if ' om ' in start_str:
                        start_date = datetime.strptime(start_str, '%A %d %B %Y om %H:%M')
                        end_date = datetime.strptime(end_str, '%A %d %B %Y om %H:%M')
                    else:
                        # Try direct format
                        try:
                            start_date = datetime.strptime(start_str, '%A %d %B %Y %H:%M')
                            end_date = datetime.strptime(end_str, '%A %d %B %Y %H:%M')
                        except ValueError:
                            # If that fails, try with different format
                            start_date = datetime.strptime(start_str.strip(), '%A %d %B %Y')
                            end_date = datetime.strptime(end_str.strip(), '%A %d %B %Y')
                            # Set default times if only dates are provided
                            start_date = start_date.replace(hour=9, minute=0)
                            end_date = end_date.replace(hour=17, minute=0)
        elif ' van ' in date_str:
            # Single day event with only start time
            date, start_time = date_str.split(' van ')
            start_date = datetime.strptime(f"{date} {start_time}", '%A %d %B %Y %H:%M')
            end_date = start_date + timedelta(hours=2)  # Assume 2-hour duration
        elif ' vanaf ' in date_str:
            # Event with "vanaf" format
            start_date = datetime.strptime(date_str, '%A %d %B %Y vanaf %H:%M')
            end_date = start_date + timedelta(hours=2)  # Assume 2-hour duration
        elif ' om ' in date_str:
            # Event with "om" format
            try:
                parts = date_str.split(' om ')
                date_part = parts[0]
                time_part = parts[1]
                start_date = datetime.strptime(f"{date_part} {time_part}", '%A %d %B %Y %H:%M')
                end_date = start_date + timedelta(hours=2)  # Assume 2-hour duration
            except ValueError:
                # Handle complex formats
                print(f"Complex format for event: {title}")
                continue
        else:
            # Fallback for unrecognized formats
            print(f"Unrecognized date format for event: {title}")
            continue

        # Set timezone to Amsterdam
        amsterdam_tz = pytz.timezone('Europe/Amsterdam')
        start_date = amsterdam_tz.localize(start_date)
        end_date = amsterdam_tz.localize(end_date)

        # Add event details to the calendar
        event.add('summary', title)
        event.add('description', f"{description}\n\nMore info: {event_url}")
        event.add('dtstart', start_date)
        event.add('dtend', end_date)
        event.add('url', event_url)

        # Extract and add categories/tags if available
        tags = []
        tag_elems = event_div.find_all('span', class_='bg-yellow-light rounded-sm md:rounded-full text-xs md:font-bold text-green py-0.5 px-1.5 md:px-2.5 md:py-1 whitespace-nowrap')
        if tag_elems:
            for tag_elem in tag_elems:
                tags.append(tag_elem.text.strip())
            if tags:
                event.add('categories', tags)

        cal.add_component(event)
    except ValueError as e:
        print(f"Could not parse date for event: {title}")
        print(f"Error: {e}")
        print(f"Date string: {date_str}")
        # Continue with the next event instead of stopping

# Generate iCal file
ical_content = cal.to_ical()

def main(file_name='play_nijmegen_events.ics'):
    # Save to file
    with open(file_name, 'wb') as f:
        f.write(ical_content)

    print(f"iCal file '{file_name}' has been created with {len(cal.subcomponents)} events.")

if __name__ == '__main__':
    if len(sys.argv) == 2:
        main(sys.argv[1])
    else:
        main()
