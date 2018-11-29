cd ${WORKSPACE}

wget https://developer.salesforce.com/media/salesforce-cli/sfdx-linux-amd64.tar.xz

mkdir -p sfdx

tar xJf sfdx-linux-amd64.tar.xz -C sfdx --strip-components 1

./sfdx/install

which sfdx