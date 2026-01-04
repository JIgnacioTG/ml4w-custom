#!/usr/bin/env python
import os
import subprocess
import sys

import requests

REGION = "es-MX"
BASE_URL = f"https://bing.biturl.top/?resolution=UHD&format=json&index=0&mkt={REGION}"
BASE_PATH = os.path.join(os.environ.get("HOME", os.path.expanduser("~")), ".local/share/backgrounds")


def ensure_directory(path):
    os.makedirs(path, exist_ok=True)


def fetch_wallpaper_metadata():
    response = requests.get(BASE_URL, timeout=10)
    return response.json()


def extract_filename_from_url(url):
    return url.split("=")[-1]


def download_wallpaper(url, filename):
    response = requests.get(url, stream=True, timeout=10)
    with open(filename, "wb") as file:
        for chunk in response.iter_content(chunk_size=8192):
            file.write(chunk)


def set_wallpaper(filename):
    subprocess.run(["waypaper", "--wallpaper", filename], check=True)


def main():
    try:
        ensure_directory(BASE_PATH)

        metadata = fetch_wallpaper_metadata()
        wallpaper_url = metadata["url"]
        filename = extract_filename_from_url(wallpaper_url)

        filepath = os.path.join(BASE_PATH, filename)

        if os.path.exists(filepath):
            return

        download_wallpaper(wallpaper_url, filepath)
        set_wallpaper(filepath)
    except requests.RequestException as e:
        print(f"Network error while downloading wallpaper: {e}", file=sys.stderr)
        sys.exit(1)
    except OSError as e:
        print(f"File system error: {e}", file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"Waypaper command failed: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
