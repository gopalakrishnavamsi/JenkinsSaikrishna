<!-- Lightning dependency apps must do the following: -->
<!-- 1. Set access control to global -->
<!-- 2. Extend from either ltng:outApp or ltng:outAppUnstyled. -->
<!-- 3. List as a dependency every component that is referenced in a call to $Lightning.createComponent() -->
<aura:application extends="ltng:outApp" access="global">
    <aura:dependency resource="c:GenTemplate"/>
    <aura:dependency resource="markup://force:*" type="EVENT"/>
</aura:application>
