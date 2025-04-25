#!/bin/bash

TARGET="example.com"
OUTPUT_DIR="pentest_results"
DEFECTDOJO_URL="http://your-defectdojo-instance/api/v2"
API_KEY="your_api_key"
mkdir -p $OUTPUT_DIR

# Step 1: Information Gathering
echo "[+] Running Nmap Scan..."
nmap -A -T4 -oX $OUTPUT_DIR/nmap_scan.xml $TARGET

echo "[+] Finding Subdomains..."
subfinder -d $TARGET > $OUTPUT_DIR/subdomains.txt

echo "[+] Directory Enumeration..."
gobuster dir -u http://$TARGET -w /usr/share/wordlists/dirb/common.txt -o $OUTPUT_DIR/directories.txt

# Step 2: SQL Injection Test
echo "[+] Testing for SQL Injection..."
sqlmap -u "http://$TARGET/login.php?id=1" --batch --json-output > $OUTPUT_DIR/sqlmap_results.json

# Step 3: XSS Testing
echo "[+] Testing for XSS Vulnerabilities..."
dalfox url "http://$TARGET/search?q=test" -o $OUTPUT_DIR/xss_results.txt

# Step 4: File Upload & Hidden Paths
echo "[+] Finding Upload Locations..."
ffuf -u http://$TARGET/FUZZ -w /usr/share/wordlists/dirb/common.txt -o $OUTPUT_DIR/ffuf_results.txt

# Step 5: SSRF Testing
echo "[+] Testing for SSRF Vulnerabilities..."
curl -X GET "http://$TARGET/fetch?url=http://169.254.169.254/latest/meta-data/" > $OUTPUT_DIR/ssrf_results.txt

# Step 6: Web Application Scan
echo "[+] Running Nikto Scan..."
nikto -h http://$TARGET -Format json -o $OUTPUT_DIR/nikto_results.json

# Step 7: Upload Results to DefectDojo
echo "[+] Uploading Nmap Scan to DefectDojo..."
curl -X POST "$DEFECTDOJO_URL/import-scan/" \
    -H "Authorization: Token $API_KEY" \
    -H "Content-Type: multipart/form-data" \
    -F "scan_type=Nmap Scan" \
    -F "file=@$OUTPUT_DIR/nmap_scan.xml"

echo "[+] Uploading SQLMap Scan to DefectDojo..."
curl -X POST "$DEFECTDOJO_URL/import-scan/" \
    -H "Authorization: Token $API_KEY" \
    -H "Content-Type: multipart/form-data" \
    -F "scan_type=SQLMap Scan" \
    -F "file=@$OUTPUT_DIR/sqlmap_results.json"

echo "[+] Uploading Nikto Scan to DefectDojo..."
curl -X POST "$DEFECTDOJO_URL/import-scan/" \
    -H "Authorization: Token $API_KEY" \
    -H "Content-Type: multipart/form-data" \
    -F "scan_type=Nikto Scan" \
    -F "file=@$OUTPUT_DIR/nikto_results.json"

echo "[+] Penetration Testing Completed! Results uploaded to DefectDojo."
