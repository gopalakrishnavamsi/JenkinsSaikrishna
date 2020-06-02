<!-- Lightning dependency apps must do the following: -->
<!-- 1. Set access control to global -->
<!-- 2. Extend from either ltng:outApp or ltng:outAppUnstyled. -->
<!-- 3. List as a dependency every component that is referenced in a call to $Lightning.createComponent() -->
<aura:application description="EnvelopeConfigurationDeleteApp" extends="ltng:outApp" access="global">
    <aura:dependency resource="markup://c:EnvelopeConfigurationDelete"/>
    <aura:dependency resource="markup://force:navigateToObjectHome" type="EVENT"/>
</aura:application>