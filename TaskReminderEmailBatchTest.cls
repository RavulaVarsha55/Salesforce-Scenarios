@isTest(seeAlldata=false)
public class TaskReminderEmailBatchTest {
    public static RecordType complianceRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Compliance' AND SObjectType = 'Task' LIMIT 1];
    public static RecordType crossSellRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Cross_Sell' AND SObjectType = 'Task' LIMIT 1];
    public static RecordType winBackRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Winback' AND SObjectType = 'Task' LIMIT 1];
    public static Profile p = [select id from profile where name like '%SRx Sales%' limit 1];
    
    @testSetup
    static void setupTestData() {
        User u = new User(Alias = 'satya', Email= 'varshadr86@drreddys.com', 
                          EmailEncodingKey='UTF-8', LastName='Satya', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US',  
                          TimeZoneSidKey='America/New_York', UserName= 'satyakalyalaby@drreddys.com',profileId=p.Id); 
        insert u; 
    }
    @isTest
    static void batchTest() {
        User u =[SELECT Id,Name,FirstName,Email from User where  Email=:'varshadr86@drreddys.com'];
        // Insert a test Task record to work with
        List<Task> taskList= new  List<Task>();
        Task testTask = new Task(
            Subject = 'Test Task',
            Status = 'Completed',
            Task_Type__c = 'Compliance',  // This will trigger the compliance logic
            Product_Manager__c = u.Email,
            Account_manager_Email__c = u.Email,
            Customer_Name__c = 'Test Customer',
            RecordTypeId = complianceRecordType.Id,
            AnnualisedOppor_dollar_Final__c = 250000.34,
            ownerId=u.id// Assign the correct record type
        );
        Task testTask1 = new Task(
            Subject = 'Test Task235',
            Status = 'Open',
            Task_Type__c = 'Compliance',  // This will trigger the compliance logic
            Product_Manager__c = u.Email,
            Account_manager_Email__c = u.Email,
            Customer_Name__c = 'Test Customer',
            RecordTypeId = complianceRecordType.Id,
            AnnualisedOppor_dollar_Final__c = 250000.34,
            ownerId=u.id// Assign the correct record type
        );
        Task testTask12 = new Task(
            Subject = 'Test Task132',
            Status = 'Open',
            Task_Type__c = 'Cross_Sell',  // This will trigger the  logic
            Product_Manager__c = u.Email,
            Account_manager_Email__c = u.Email,
            Customer_Name__c = 'Test Customer',
            RecordTypeId = crossSellRecordType.Id,
            BottomLineImpact_dollar__c = 250000.34,
            ownerId=u.id// Assign the correct record type
        );
        Task testTask13 = new Task(
            Subject = 'Test Task23',
            Status = 'Completed',
            Task_Type__c = 'Cross_Sell',  // This will trigger the compliance logic
            Product_Manager__c = u.Email,
            Account_manager_Email__c = u.Email,
            Customer_Name__c = 'Test Customer',
            RecordTypeId = crossSellRecordType.Id,
            BottomLineImpact_dollar__c = 250000.34,
            ownerId=u.id// Assign the correct record type
        );
        Task testTask14 = new Task(
            Subject = 'Test Task14',
            Status = 'Completed',
            Task_Type__c = 'Winback',  // This will trigger the compliance logic
            Product_Manager__c = u.Email,
            Account_manager_Email__c = u.Email,
            Customer_Name__c = 'Test Customer',
            RecordTypeId = winBackRecordType.Id,
            BottomLineImpact_dollar__c = 250000.34,
            ownerId=u.id// Assign the correct record type
        );
        Task testTask15 = new Task(
            Subject = 'Test Task14',
            Status = 'Open',
            Task_Type__c = 'Winback',  // This will trigger the compliance logic
            Product_Manager__c = u.Email,
            Account_manager_Email__c = u.Email,
            Customer_Name__c = 'Test Customer',
            RecordTypeId = winBackRecordType.Id,
            BottomLineImpact_dollar__c = 250000.34,
            ownerId=u.id// Assign the correct record type
        );
        taskList.add(testTask);
        taskList.add(testTask1);
        taskList.add(testTask12);
        taskList.add(testTask13);
        taskList.add(testTask14);
        taskList.add(testTask15);
        
        insert taskList;
        // Start the test
        Test.startTest();
        TaskReminderEmailBatch task = new TaskReminderEmailBatch();
        Database.executeBatch(task);
        Test.stopTest();
    }
    @isTest
    static void scheduleTest()
    {
        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2042';
        TaskReminderEmailBatch task = new TaskReminderEmailBatch();
        String jobId = System.schedule('testBasicScheduledApex',CRON_EXP, task);   
        Test.stopTest();
    }
    
}