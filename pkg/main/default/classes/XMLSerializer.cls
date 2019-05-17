public class XMLSerializer {

    public static String fromPrimitive(final String data, final String tag) {
        return getTag(tag.capitalize(), true) + data + getTag(tag.capitalize(), false);
    }
    
    public static String fromPrimitive(final Integer data, final String tag) {
        return fromPrimitive(String.valueOf(data), tag);
    } 
    
    public static String fromPrimitive(final Double data, final String tag) {
        return fromPrimitive(String.valueOf(data), tag);
    }  

    public static String fromPrimitive(final Object data, final String tag) {
        return fromPrimitive(data.toString(), tag);
    }      
   
    public static String fromObject(final Set<String> properties, final Object data, final String parentTag) {
        Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(data));
        List<String> tags = new List<String>();
        for (String key : properties) {
            if (dataMap.get(key) != null) tags.add(fromPrimitive(dataMap.get(key), key.capitalize()));
        }
        return fromPrimitive(String.join(tags, ''), parentTag);
    }
    
    public static String fromObject(final Set<String> properties, final Map<String, Object> data, final String parentTag) {
        List<String> tags = new List<String>();
        for (String key : properties) {
            if (data.get(key) != null) tags.add(fromPrimitive(data.get(key), key.capitalize()));
        }
        return fromPrimitive(String.join(tags, ''), parentTag);
    }    
    
    public static String fromIteratable(final Set<String> properties, final List<Object> data, final String parentTag, final string itemTag) {
        String results = '';
        for (Object obj : data) {
            results += fromObject(properties, obj, itemTag);
        }
        return fromPrimitive(results, parentTag);
    }
    
    public static String fromIteratable(final Set<String> properties, final List<UUID> data, final String parentTag, final string itemTag) {
        String results = '';
        for (UUID id : data) {
            results += fromObject(properties, new Map<String, String>{ 'id' => id.toString() }, itemTag);
        }
        return fromPrimitive(results, parentTag);
    }    
    
    public static String toXMLForm(final Set<String> properties, final Map<String, Object> data, final String parentTag) {
        String results = '';
        for (String prop : properties) {
            results += data.get(prop);
        }
        return fromPrimitive(results, parentTag);
    }     
    
    @TestVisible
    private static String getTag(final String propertyName, final Boolean isOpen) {
        if (isOpen) return '<'+ propertyName + '>';
        return '</'+ propertyName + '>';
    }
    
    public static Boolean isValid(final String xmlInput) {
        try {
            DOM.Document doc = new DOM.Document();
            doc.load(xmlInput); 
            //Will throw error if XML string has bad format.
        } catch(Exception err) {
            return false;
        }
        
        return true;
    }

}