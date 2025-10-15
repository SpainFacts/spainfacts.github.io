import json
import re
import requests

def clean_date(date_str):
    if not date_str:
        return None

    # Search for a four-digit year
    match = re.search(r'\b(\d{4})\b', date_str)
    if match:
        return int(match.group(1))

    # Search for a two-digit year and infer the century
    match = re.search(r'\b(\d{2})\b', date_str)
    if match:
        year = int(match.group(1))
        return 2000 + year if year <= 24 else 1900 + year

    return None

def clean_data(records):
    cleaned_records = []
    for record in records:
        # Extract and clean the 'from_date' field to get the creation year
        from_date = record.get('from_date')
        creation_year = clean_date(from_date) if from_date else None

        # Standardize the 'is_active' field to a boolean
        is_active_str = record.get('is_active', 'No').lower()
        is_active = is_active_str in ['si', 'sí', 'yes']

        # Get the 'scope' or default to 'Unknown'
        scope = record.get('scope', 'Unknown')

        cleaned_records.append({
            'name': record.get('name'),
            'creation_year': creation_year,
            'is_active': is_active,
            'scope': scope,
        })
    return cleaned_records

def main():
    # Fetch data from the URL
    url = "https://observatoriospublicos.es/observatories.json"
    response = requests.get(url)
    data = response.json()

    # Clean the data
    cleaned_data = clean_data(data)

    # Save the cleaned data to a new JSON file
    with open('scripts/observatorios_cleaned.json', 'w') as f:
        json.dump(cleaned_data, f, indent=2)

if __name__ == "__main__":
    main()