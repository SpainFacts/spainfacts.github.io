# ...existing code...
import json
import re
import requests
import os
import logging
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

def clean_date(date_str):
    if not date_str:
        return None

    match = re.search(r'\b(\d{4})\b', date_str)
    if match:
        return int(match.group(1))

    match = re.search(r'\b(\d{2})\b', date_str)
    if match:
        year = int(match.group(1))
        return 2000 + year if year <= 24 else 1900 + year

    return None

def clean_data(records):
    cleaned_records = []
    for record in records:
        from_date = record.get('from_date')
        creation_year = clean_date(from_date) if from_date else None

        is_active_str = str(record.get('is_active', 'No')).lower()
        is_active = is_active_str in ['si', 'sí', 'yes', 'true', '1']

        scope = record.get('scope', 'Unknown')

        cleaned_records.append({
            'name': record.get('name'),
            'creation_year': creation_year,
            'is_active': is_active,
            'scope': scope,
        })
    return cleaned_records

def get_session_with_retries(total_retries=5, backoff_factor=0.5, status_forcelist=(429, 500, 502, 503, 504)):
    session = requests.Session()
    retries = Retry(
        total=total_retries,
        backoff_factor=backoff_factor,
        status_forcelist=status_forcelist,
        allowed_methods=["GET", "POST"]
    )
    adapter = HTTPAdapter(max_retries=retries)
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    return session

def fetch_data(url, timeout=10):
    session = get_session_with_retries()
    try:
        logging.info("Fetching %s", url)
        resp = session.get(url, timeout=timeout)
        resp.raise_for_status()
        return resp.json()
    except requests.RequestException as e:
        logging.error("Request failed: %s", e)
        raise

def save_cleaned(data, out_path):
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    logging.info("Saved cleaned data to %s", out_path)

def main(use_cache_on_error=True):
    url = "https://observatoriospublicos.es/observatories.json"
    script_dir = os.path.dirname(os.path.abspath(__file__))
    out_file = os.path.join(script_dir, 'observatorios_cleaned.json')
    cache_file = os.path.join(script_dir, 'observatorios_cache.json')

    try:
        data = fetch_data(url, timeout=10)
        # Optionally update local cache of raw response
        try:
            with open(cache_file, 'w', encoding='utf-8') as cf:
                json.dump(data, cf, ensure_ascii=False)
        except Exception:
            logging.warning("Could not write cache file")

    except Exception as err:
        logging.warning("Falling back to local cache due to fetch error.")
        if use_cache_on_error and os.path.exists(cache_file):
            with open(cache_file, 'r', encoding='utf-8') as cf:
                data = json.load(cf)
                logging.info("Loaded data from cache %s", cache_file)
        else:
            logging.error("No cache available and fetch failed: %s", err)
            return 1

    cleaned_data = clean_data(data)
    save_cleaned(cleaned_data, out_file)
    return 0

if __name__ == "__main__":
    exit(main())
# ...existing code...