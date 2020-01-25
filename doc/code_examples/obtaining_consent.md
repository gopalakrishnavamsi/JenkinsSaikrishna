# Obtaining consent with the Apex Toolkit

This example shows you how to obtain consent using DocuSign OAuth in your application using the Apex Toolkit. 

## Before You Begin
1. Install the [DocuSign Apps Launcher](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FK9gtUAD) managed package. You must install or upgrade to version 2.2 or later.
1. Navigate to the DocuSign Setup tab and complete the login step.
1. Use the code provided in your application's Apex classes as a basis for your implementation of obtaining user consent.

## 1. Get a login URL.
When a user invokes a method that requires a DocuSign API callout, the Apex Toolkit will verify that user has a valid access token for the request. If the user does not have a valid token, the Apex Toolkit will attempt to exchange a JWT token for an access token. If this call fails because the user has not granted their consent, the Apex Toolkit throws a [`dfsle.APIException`]() with error code [`dsfle.APIErrorCode.CONSENT_REQUIRED`]().

After detecting the consent requirement, call the [`dfsle.AuthService.getLoginUrl`]() method. This takes a single argument: the path to a page you want to redirect users to after completing the consent flow. Any query string parameters specified will be passed through as-is.

```Apex
Url loginUrl;
try {
    dfsle.EnvelopeService.sendEnvelope(envelope, true);
} catch (dfsle.APIException ex) {
    if (ex.error.code == dfsle.APIErrorCode.CONSENT_REQUIRED) {
        // generate starting URL for consent flow
        loginUrl = dfsle.AuthService.getLoginUrl('/apex/myPage?myState=whatever');
    } else {
        // handle other errors
    }
} 
``` 

Your redirect page must reside on your current Salesforce org--no external redirects are allowed. For example, `/apex/myPage?myState=whatever` is a valid redirect while `https://example.com/myPage?myState=whatever` is invalid. The Apex Toolkit will not throw an exception in the latter case but will prepend a forward slash to your redirect URL so it will be treated as a relative path on the current Salesforce host: `/https://example.com/myPage?myState=something`.

The generated login URL is valid only once for the requesting user.

## 2. Open login URL.

Once you have the DocuSign login URL, redirect your user to it. Bear in mind that you cannot iframe this URL; it must either be a full-page redirect or opened in a new window or tab.

To open the login URL in a new window or tab in either Visualforce or Lightning:
```Javascript
window.open(loginUrl, '_blank');
```

To open the login URL in the current window in Lightning:
```Javascript
var navEvent = $A.get('e.force:navigateToURL');
navEvent.setParam('url', loginUrl);
navEvent.fire();
```

To open the login URL in the current window in Visualforce:
```javascript
window.location.assign(loginUrl); // or window.location.replace(loginUrl);
```

## 3. Check the login result.

Once the user has logged into DocuSign and completed the consent flow, they will be redirected to your page. The Apex Toolkit adds query string parameters describing the result of this flow:
* `dfsle__status`: Either `Success` or `Failure`.
* `dfsle__message`: Additional details in case of failures.

You can redirect to a URL-addressable Lightning component:
```xhtml
<aura:component implements="lightning:isUrlAddressable">
    <aura:handler name="init" value="{!this}" action="{!c.onInit}"/>
</aura:component>
```

With Javascript controller:
```javascript
({
  onInit: function (component, event, helper) {
    var status = component.get('v.pageReference.state.dfsle__status');
    var message = component.get('v.pageReference.state.dfsle__message');
    if (status === 'Success') {
      // continue original transaction
    } else {
      // display message
    }
  }
});
```

Or use a Visualforce page to handle the redirect:
```xhtml
<apex:page controller="MyController" action="{!c.verifyVisualforceResult}"/>
```

With Apex controller:
```Apex
public with sharing class MyController {

    public PageReference verifyVisualforceResult() {
        String status = ApexPages.currentPage().getParameters().get('dfsle__status');
        String message = ApexPages.currentPage().getParameters().get('dfsle__message');
        if (status == 'Success') {
            // continue original transaction
        } else {
            // display message
        }
    }
}
```

## 4. Continue original transaction.

After the user has granted consent, they are now able to invoke other Apex Toolkit functions without further interactions with DocuSign’s OAuth service.

Users have the ability to revoke their consent at any time, so your application must be prepared to display appropriate messaging and send them through the consent flow again.

