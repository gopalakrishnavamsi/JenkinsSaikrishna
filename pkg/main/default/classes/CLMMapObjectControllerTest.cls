@isTest
public class CLMMapObjectControllerTest {
    @isTest
    public static void getMappedObjectsListTest(){
        System.assert( CLMMapObjectController.getMappedObjectsList()!=null);
    }
    @isTest
    public static void getAllObjectsTest(){
        System.assert( CLMMapObjectController.getAllObjects().size()!=0);
    }
    @isTest
    public static void getAllObjectFieldsTest(){
        System.assert( CLMMapObjectController.getAllObjectFields('Case', false).size()!=0);
    }
}