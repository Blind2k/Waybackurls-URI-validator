#! /bin/bash
# -*- coding: UTF-8 -*-

# This is a complimentary Bash/Shell/zsh script to filter all of the URLs returned from the awysome "waybackurls" tool
# https://github.com/tomnomnom/waybackurls/tree/master
# This script will:
#-- Sort and orgnize the original list from waybackurls
#-- Check if the returned URLs still active
#-- Completly passive using waybackMachine
# If you need any thing, please contact me.
# TODO: Get andry on this script one day so I will have to convert this to multithread processing to check if URLs available at a higher rate.

# Function to check and install missing tools
function check_that_the_machine_have_everything_to_run() {
  declare -a tools=("waybackurls" "jq" "wc")
  for tool in "${tools[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
      echo "Tool $tool not found."
      exit 1
    fi
  done
  
  if [ -z "$1" ]; then
    echo "Error: No argument provided. Please provide a domain."
    exit 1
  fi
  echo "GREAT! We are good to go"
}
check_that_the_machine_have_everything_to_run $1

# Here the script starts
echo "Prepering dir to save output files"
mkdir -p ./waybackurls_script && cd waybackurls_script

echo "Current Directory: $(pwd)"
waybackurls $1 | sort | uniq > "waybackurls_$1-sorted.txt"
echo "Got a list with $(wc -l < "waybackurls_$1-sorted.txt") URLs"

echo "Checking which URL is still available"
while read -r url; do
  response=$(curl --http2 -k --resolve "archive.org:443:207.241.224.2" -s --max-time 10 "https://archive.org/wayback/available?url=${url}")

  # Extract the status code using jq. In case there is no code, the URL isn't active
  status=$(echo $response | jq -r '.archived_snapshots.closest.status // empty')

  # Check if the status exists
  if [ -n "$status" ]; then
    # save the URL
    echo "${url}" >> "waybackurls_$1-available.txt"
  elif [ -z "$status" ]; then
    echo "No status found for URL: $url"
  fi
done < "waybackurls_$1-sorted.txt"

total_urls=$(wc -l < "waybackurls_$1-sorted.txt")
available_urls=$(wc -l < "waybackurls_$1-available.txt")
echo "Processed $total_urls URLs, found $available_urls available snapshots."
echo "Thank you and have a great day!"
