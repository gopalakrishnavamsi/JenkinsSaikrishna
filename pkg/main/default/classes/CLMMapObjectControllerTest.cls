@isTest
public class CLMMapObjectControllerTest {
    @isTest
    public static void getMappedObjectsListTest(){
        System.assert( CLMMapObjectController.getMappedObjectsList()!='');
    }
    @isTest
    public static void getAllObjectsTest(){
        System.assert( CLMMapObjectController.getAllObjects().size()!=0);
    }
    @isTest
    public static void getAllObjectFiledsTest(){
        System.assert( CLMMapObjectController.getAllObjectFileds('Case').size()!=0);
    }
}