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

# Find all event divs
event_divs = soup.find_all('div', class_='bg-white py-4 md:py-0 w-full rounded-lg md:rounded-bl-3xl overflow-hidden flex shadow-sm cursor-pointer relative')

for event_div in event_divs:
    event = Event()

    # Extract event details
    title = event_div.find('a', class_='text-xl').text.strip()
    description = event_div.find('p', class_='text-sm text-gray-800 py-2').text.strip()
    date_str = event_div.find('div', class_='text-green text-sm md:font-bold').text.strip()

    # Extract the event URL
    event_url = event_div.find('a', class_='text-xl')['href']
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
                # Multi-day event
                start_str, end_str = date_str.split(' tot ')
                start_date = datetime.strptime(start_str, '%A %d %B %Y om %H:%M')
                end_date = datetime.strptime(end_str, '%A %d %B %Y om %H:%M')
        elif ' van ' in date_str:
            # Single day event with only start time
            date, start_time = date_str.split(' van ')
            start_date = datetime.strptime(f"{date} {start_time}", '%A %d %B %Y %H:%M')
            end_date = start_date + timedelta(hours=2)  # Assume 2-hour duration
        else:
            # Event without explicit end time
            start_date = datetime.strptime(date_str, '%A %d %B %Y vanaf %H:%M')
            end_date = start_date + timedelta(hours=2)  # Assume 2-hour duration

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

        cal.add_component(event)
    except ValueError as e:
        print(f"Could not parse date for event: {title}")
        print(f"Error: {e}")
        print(f"Date string: {date_str}")

# Generate iCal file
ical_content = cal.to_ical()

def main(file_name='play_nijmegen_events.ics'):
    # Save to file
    with open(file_name, 'wb') as f:
        f.write(ical_content)

    print(f"iCal file '{file_name}' has been created.")

if __name__ == '__main__':
    if len(sys.argv) == 2:
        main(sys.argv[1])
    else:
        main()
