
# Salesforce CPQ/Billing scratch org setup instructions

Below are the brief instructions to set up a scratch Org and to test Salesforce Billing MVP features

## Create a new scratch Org from features/BillingMVP branch
#### SFDX commands
1. sfdx force:org:create -f ./etc/developerScratch.json -s -d 30 -a <scratch org name>
2. sfdx force:org:open
3. sfdx force:user:password:generate
## Log into the scratch Org and install Salesforce CPQ and Salesforce Billing packages.
1. Go to the URL https://install.steelbrick.com/
2. Search for 'Salesforce CPQ'.
3. Select the Sandbox link of the latest Package version available (Example: Summer '20)
4. Click on the link to install 'Salesforce CPQ'. 
5. Wait for 5 to 10 minutes, upon installation you will receive an email about successful installation.
6. Go back to the URL https://install.steelbrick.com/
7. Search for 'Salesforce Billing'.
8. Select the Sandbox link of the latest Package version available (Example: Summer '20)
9. Click on the link to install 'Salesforce Billing'. 
10. Wait for 5 to 10 minutes, upon installation you will receive an email about successful installation.
11. If you are using a partner Org, please use Production links for both the packages.

## Push the latest code from features/BillingMVP branch
1. Once the Salesforce CPQ and Salesforce Billing managed packages are installed, push the latest code from features/BillingMVP branch using: 
   sfdx force:source:push -u <scratch org name>

## Data setup in Salesforce Billing
1. Once scratch org is setup, go to installed packages in Setup menu.
2. Click on 'configure' for 'Salesforce Billing' package.
3. Go to 'Additional Settings' in Billing configuration and 'Insert Sampledata'. That feature will create sample data in your scratch org.

## Salesforce Billing Data flow
Opportunity -> Quote -> Order -> Invoice
Opportunity line items -> Quote line items -> Order line items -> Invoice line items.
