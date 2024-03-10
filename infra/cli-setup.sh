# download and install AWS cli
echo "Downloading AWS cli"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
echo "Downloaded AWS cli"

echo "Extracting AWS cli"
unzip awscliv2.zip
echo "Extracted AWS cli"

echo "Installing AWS cli"
sudo ./aws/install
echo "Installed AWS cli"

# download and install jq
echo "Installing jq"
wget https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64
mv jq-linux-amd64 jq
chmod +x jq
echo "Installed jq"