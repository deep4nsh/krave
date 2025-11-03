#!/bin/bash

# Test script to verify Google Custom Search API keys work
echo "Testing Google Custom Search API..."
echo "======================================"
echo ""

# Read API credentials from secrets.properties
API_KEY=$(grep "google.custom_search.api_key=" assets/secrets.properties | cut -d'=' -f2)
ENGINE_ID=$(grep "google.custom_search.engine_id=" assets/secrets.properties | cut -d'=' -f2)

echo "Engine ID: $ENGINE_ID"
echo "API Key: ${API_KEY:0:10}...${API_KEY: -5}"
echo ""

# Test with sample menu items
test_items=("pizza" "burger" "pasta" "biryani" "dosa")

for item in "${test_items[@]}"; do
    echo "Searching for: $item"
    response=$(curl -s "https://www.googleapis.com/customsearch/v1?key=$API_KEY&cx=$ENGINE_ID&q=$item&searchType=image&num=1")
    
    # Check if response contains items
    if echo "$response" | grep -q '"items"'; then
        image_url=$(echo "$response" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['items'][0]['link'] if 'items' in data and len(data['items']) > 0 else 'No image found')")
        echo "✅ Found: $image_url"
    else
        error=$(echo "$response" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('error', {}).get('message', 'Unknown error'))")
        echo "❌ Error: $error"
    fi
    echo ""
    sleep 1  # Rate limiting
done

echo "======================================"
echo "Test complete!"
