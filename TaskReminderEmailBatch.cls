/*----------------------------------------------------------------------------------------------
Author:        Varsha
Company:       Absyz
Description:   To handle bulk Email reminders for all Tasks. 
Inputs:        NA
Test Class:    

History
15-10-2024     Varsha      Initial Release
 
---------------------------------------------------------------
*/    
global class TaskReminderEmailBatch implements Database.Batchable<sObject>,Schedulable {
    //These custom labels contain list of profiles/users in comme separated way for which reminders need to be sent
    public static List<String> profileList=System.Label.ProfilesForReminder.split(',');
    public static List<String> Users=System.Label.UsersForReminder.split(',');
    public static Id complianceRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Compliance' LIMIT 1].Id;
    public static Id crossSellRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Cross_Sell' LIMIT 1].Id;
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        if(!Test.isrunningTest()){
            return Database.getQueryLocator('SELECT Id,Name,FirstName,Email from User WHERE profile.Name IN :profileList AND Name IN :Users');
        }
        else{
            return Database.getQueryLocator('SELECT Id,Name,FirstName,Email from User where  Email= \'varshadr86@drreddys.com\'');     
        }
    }
    
    public void execute(Database.BatchableContext bc, List<User> userList){
        List<String> recordTypes = new List<String>{'Compliance','Cross_Sell','Winback'};
        Map<Id, Map<String, Integer>> ownervsCountInt = new Map<Id, Map<String, Integer>> ();
        /*Map of ownerid and Map of entity and count is created in this way
		* 00541000005LksRAAS=>{compAssigned=>2,CompCompleted=>2,CompAssignedAmt=>132133}
        */
        For(AggregateResult t:[SELECT OwnerId,recordtypeId,Status,count(Id) total,sum(BottomLineImpact_dollar__c) btm,sum(AnnualisedOppor_dollar_Final__c) atm  from Task where OwnerId in :userList and recordtype.developername in :recordTypes group by OwnerId,recordtypeid,status]){
           //Compliance type
            if((string)t.get('recordtypeId')==complianceRecordTypeId){
                if((string)t.get('Status')=='Completed'){
                    Integer tasksCompCompleted=(Integer)t.get('total');
                    system.debug('count'+tasksCompCompleted);
                    //first time
                    if(!ownervsCountInt.containsKey((Id)t.get('OwnerId'))){
                        ownervsCountInt.put((Id)t.get('OwnerId'),new Map<String, Integer>{'CompCompleted' =>(Integer)t.get('total'),'CompPending'=>0,'CrossCompleted'=>0,'CrossPending'=>0,'WinCompleted'=>0,'WinPending'=>0,
                            'CompCompletedAmt'=>Integer.valueOf(t.get('atm')),'CompPendingAmt'=>0,'CrossCompletedAmt'=>0,'CrossPendingAmt'=>0,'WinCompletedAmt'=>0,'WinPendingAmt'=>0});
                    }else{
                        if(ownervsCountInt.containsKey((Id)t.get('OwnerId'))){
                            Map<String, Integer> existingCount = ownervsCountInt.get((Id)t.get('OwnerId'));
                            integer UpdatedCount=existingCount.get('CompCompleted')!=null?existingCount.get('CompCompleted')+(Integer)t.get('total'):0;
                            existingCount.put('CompCompleted',UpdatedCount);
                            integer UpdatedCountAmt=existingCount.get('CompCompletedAmt')!=null?existingCount.get('CompCompletedAmt')+Integer.valueOf(t.get('atm')):0;
                            existingCount.put('CompCompletedAmt',UpdatedCountAmt);
                            ownervsCountInt.put((Id)t.get('OwnerId'),existingCount);
                        }                    
                    }
                }
                else{
                    if((string)t.get('Status')!='Closed'){
                    Integer tasksCompCompleted=(Integer)t.get('total');
                    if(!ownervsCountInt.containsKey((Id)t.get('OwnerId'))){
                        // Map<String, Integer> existingCount = new Map<String, Integer>{'Assigned'=>0};
                        ownervsCountInt.put((Id)t.get('OwnerId'),new Map<String, Integer>{'CompPending' =>(Integer)t.get('total'),'CompCompleted'=>0,'CrossCompleted'=>0,'CrossPending'=>0,'WinCompleted'=>0,'WinPending'=>0,
                            'CompCompletedAmt'=>0,'CompPendingAmt'=>Integer.valueOf(t.get('atm')),'CrossCompletedAmt'=>0,'CrossPendingAmt'=>0,'WinCompletedAmt'=>0,'WinPendingAmt'=>0});
                        
                    }else{
                        if(ownervsCountInt.containsKey((Id)t.get('OwnerId'))){
                            Map<String, Integer> existingCount = ownervsCountInt.get((Id)t.get('OwnerId'));
                            integer UpdatedCount=existingCount.get('CompPending')!=null?existingCount.get('CompPending')+(Integer)t.get('total'):0;
                            existingCount.put('CompPending',UpdatedCount);
                            integer UpdatedCountAmt=existingCount.get('CompPendingAmt')!=null?existingCount.get('CompPendingAmt')+Integer.valueOf(t.get('atm')):0;
                            existingCount.put('CompPendingAmt',UpdatedCountAmt);
                            ownervsCountInt.put((Id)t.get('OwnerId'),existingCount);                    
                        } 
                    }
                  }
                }
            }
            //Cross Sell type
            else if((string)t.get('recordtypeId')==crossSellRecordTypeId){
                if((string)t.get('Status')=='Completed'){
                    Integer tasksCompCompleted=(Integer)t.get('total');
                    //first time
                    
                    if(!ownervsCountInt.containsKey((Id)t.get('OwnerId'))){
                        ownervsCountInt.put((Id)t.get('OwnerId'),new Map<String, Integer>{'CrossCompleted' =>(Integer)t.get('total'),'CrossPending'=>0,'WinCompleted'=>0,'WinPending'=>0,'CompCompleted'=>0,'CompPending'=>0,
                            'CompCompletedAmt'=>0,'CompPendingAmt'=>0,'CrossCompletedAmt'=>Integer.valueOf(t.get('btm')),'CrossPendingAmt'=>0,'WinCompletedAmt'=>0,'WinPendingAmt'=>0});
                    }else{
                        if(ownervsCountInt.containsKey((Id)t.get('OwnerId'))){
                            Map<String, Integer> existingCount = ownervsCountInt.get((Id)t.get('OwnerId'));
                            integer UpdatedCount=existingCount.get('CrossCompleted')!=null?existingCount.get('CrossCompleted')+(Integer)t.get('total'):0;
                            existingCount.put('CrossCompleted',UpdatedCount);
                            integer UpdatedCountAmt=existingCount.get('CrossCompletedAmt')!=null?existingCount.get('CrossCompletedAmt')+Integer.ValueOf(t.get('btm')):0;
                            existingCount.put('CrossCompletedAmt',UpdatedCountAmt);
                            ownervsCountInt.put((Id)t.get('OwnerId'),existingCount);
                        } 
                    }
                }
                else{
                    if((string)t.get('Status')!='Closed'){
                    Integer tasksCompCompleted=(Integer)t.get('total');
                    if(!ownervsCountInt.containsKey((Id)t.get('OwnerId'))){
                        ownervsCountInt.put((Id)t.get('OwnerId'),new Map<String, Integer>{'CrossPending' =>(Integer)t.get('total'),'CrossCompleted'=>0,'WinCompleted'=>0,'WinPending'=>0,'CompCompleted'=>0,'CompPending'=>0,
                            'CompCompletedAmt'=>0,'CompPendingAmt'=>0,'CrossCompletedAmt'=>0,'CrossPendingAmt'=>Integer.valueOf(t.get('btm')),'WinCompletedAmt'=>0,'WinPendingAmt'=>0});
                        
                    }else{
                        if(ownervsCountInt.containsKey((Id)t.get('OwnerId'))){
                            Map<String, Integer> existingCount = ownervsCountInt.get((Id)t.get('OwnerId'));
                            integer UpdatedCount=existingCount.get('CrossPending')!=null?existingCount.get('CrossPending')+(Integer)t.get('total'):0;
                            existingCount.put('CrossPending',UpdatedCount);
                            integer UpdatedCountAmt=existingCount.get('CrossPendingAmt')!=null?existingCount.get('CrossPendingAmt')+Integer.ValueOf(t.get('btm')):0;
                            existingCount.put('CrossPendingAmt',UpdatedCountAmt);
                            ownervsCountInt.put((Id)t.get('OwnerId'),existingCount);                    
                        } 
                    }
                  }
                }
            }
            //Winback type
            else{
                if((string)t.get('Status')=='Completed'){
                    Integer tasksCompCompleted=(Integer)t.get('total');
                    //first time
                    
                    if(!ownervsCountInt.containsKey((Id)t.get('OwnerId'))){
                        ownervsCountInt.put((Id)t.get('OwnerId'),new Map<String, Integer>{'WinCompleted' =>(Integer)t.get('total'),'WinPending'=>0,'CompPending' =>0,'CompCompleted'=>0,'CrossCompleted'=>0,'CrossPending'=>0,
                            'CompCompletedAmt'=>0,'CompPendingAmt'=>0,'CrossCompletedAmt'=>0,'CrossPendingAmt'=>0,'WinCompletedAmt'=>Integer.ValueOf(t.get('btm')),'WinPendingAmt'=>0});
                    }else{
                        Map<String, Integer> existingCount = ownervsCountInt.get((Id)t.get('OwnerId'));
                        integer UpdatedCount=existingCount.get('WinCompleted')!=null?existingCount.get('WinCompleted')+(Integer)t.get('total'):0;
                        existingCount.put('WinCompleted',UpdatedCount);
                        integer UpdatedCountAmt=existingCount.get('WinCompletedAmt')!=null?existingCount.get('WinCompletedAmt')+Integer.ValueOf(t.get('btm')):0;
                        existingCount.put('WinCompletedAmt',UpdatedCountAmt);
                        ownervsCountInt.put((Id)t.get('OwnerId'),existingCount);
                    }
                   
                }
                else{
                    if((string)t.get('Status')!='Closed'){
                    Integer tasksCompCompleted=(Integer)t.get('total');
                    if(!ownervsCountInt.containsKey((Id)t.get('OwnerId'))){
                        ownervsCountInt.put((Id)t.get('OwnerId'),new Map<String, Integer>{'WinPending' =>(Integer)t.get('total'),'WinCompleted'=>0,'CompPending' =>0,'CompCompleted'=>0,'CrossCompleted'=>0,'CrossPending'=>0,
                            'CompCompletedAmt'=>0,'CompPendingAmt'=>0,'CrossCompletedAmt'=>0,'CrossPendingAmt'=>0,'WinCompletedAmt'=>0,'WinPendingAmt'=>Integer.ValueOf(t.get('btm'))});
                        
                    }else{
                        Map<String, Integer> existingCount = ownervsCountInt.get((Id)t.get('OwnerId'));
                        integer UpdatedCount=existingCount.get('WinPending')!=null?existingCount.get('WinPending')+(Integer)t.get('total'):0;
                        existingCount.put('WinPending',UpdatedCount);
                        integer UpdatedCountAmt=existingCount.get('WinPendingAmt')!=null?existingCount.get('WinPendingAmt')+Integer.ValueOf(t.get('btm')):0;
                        existingCount.put('WinPendingAmt',UpdatedCountAmt);
                        ownervsCountInt.put((Id)t.get('OwnerId'),existingCount);                    
                    } 
                  }
                }  
            }
        }
        // build Url for link to all Tasks
        String UrlList = (String)Url.getOrgDomainUrl().toExternalForm();
        UrlList=UrlList+'/lightning/o/Task/list?filterName=All_Tasks';    
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        // Capture bright support email address from which all the email reminders will be sent
        OrgWideEmailAddress org=[select id,Address from OrgWideEmailAddress where DisplayName='BRIGHT SUPPORT' Limit 1];
        List<String> toAddressList = new List<String>();
        for(User u:userList){
            messaging.singleEmailMessage mail = new messaging.singleEmailMessage();
            //mail.ToAddresses = new string[]{'varsha.ravula@absyz.com','agheel.kareem@absyz.com'};//for testing
            mail.setOrgWideEmailAddressId(org.Id);//uncomment before prod
           	mail.ToAddresses = new string[]{u.Email};//uncomment before prod
            mail.setSubject('Reminder Email: Tasks Waiting For Your Action');
            mail.setUseSignature(false);
            Integer compAssigned1=0;
            Integer compCompleted=0;
            Integer compPending=0;
            
            Integer crossAssigned=0;
            Integer crossCompleted=0;
            Integer crossPending=0;
            
            Integer winAssigned=0;
            Integer winCompleted=0;
            integer winPending=0;
            
            Integer compAssignedAmt=0;
            Integer compCompletedAmt=0;
            Integer compPendingAmt=0;
            
            Integer crossAssignedAmt=0;
            Integer crossCompletedAmt=0;
            Integer crossPendingAmt=0;
            
            Integer winAssignedAmt=0;
            Integer winCompletedAmt=0;
            integer winPendingAmt=0;
            
            if(ownervsCountInt.get(u.Id).get('CompPending')!=null)
                compPending=ownervsCountInt.get(u.Id).get('CompPending');
            if(ownervsCountInt.get(u.Id).get('CrossPending')!=null)
                crossPending=ownervsCountInt.get(u.Id).get('CrossPending');
            if(ownervsCountInt.get(u.Id).get('WinPending')!=null)
                winPending=ownervsCountInt.get(u.Id).get('WinPending');
            
            if(ownervsCountInt.get(u.Id).get('CompCompleted')!=null)
                compCompleted=ownervsCountInt.get(u.Id).get('CompCompleted');
            if(ownervsCountInt.get(u.Id).get('CrossCompleted')!=null)
                crossCompleted=ownervsCountInt.get(u.Id).get('CrossCompleted');
            if(ownervsCountInt.get(u.Id).get('WinCompleted')!=null)
                winCompleted=ownervsCountInt.get(u.Id).get('WinCompleted');
            
            if(ownervsCountInt.get(u.Id).get('CompPendingAmt')!=null)
                compPendingAmt=ownervsCountInt.get(u.Id).get('CompPendingAmt');
            if(ownervsCountInt.get(u.Id).get('CrossPendingAmt')!=null)
                crossPendingAmt=ownervsCountInt.get(u.Id).get('CrossPendingAmt');
            if(ownervsCountInt.get(u.Id).get('WinPendingAmt')!=null)
                winPendingAmt=ownervsCountInt.get(u.Id).get('WinPendingAmt');
            
            if(ownervsCountInt.get(u.Id).get('CompCompletedAmt')!=null)
                compCompletedAmt=ownervsCountInt.get(u.Id).get('CompCompletedAmt');
            if(ownervsCountInt.get(u.Id).get('CrossCompletedAmt')!=null)
                crossCompletedAmt=ownervsCountInt.get(u.Id).get('CrossCompletedAmt');
            if(ownervsCountInt.get(u.Id).get('WinCompletedAmt')!=null)
                winCompletedAmt=ownervsCountInt.get(u.Id).get('WinCompletedAmt');
            //Calculation of Assigned values => Assigned = Pending+Completed
            compAssigned1=comppending+compCompleted;
            crossAssigned=crossPending+crossCompleted;
            winAssigned=winPending+winCompleted;
            compAssignedAmt=comppendingAmt+compCompletedAmt;
            crossAssignedAmt=crossPendingAmt+crossCompletedAmt;
            winAssignedAmt=winPendingAmt+winCompletedAmt;
            //Strings hold the styling for the tag sin html body
            string td1 = '"font-weight:bold; text-align:center; background-color:#6900EF; color:white; padding:5px; border:1px solid #cfcfcf;"';
            string td2 = '"border:1px solid #cfcfcf; padding:5px; text-align:center; font-weight:bold;"';
            string tdGreen = '"background-color:#B1E9C8; color:#2E844A; padding:5px; text-align:center; border:1px solid #cfcfcf;"';
            string tdYellow = '"background-color:#FFF6D5; color:#E80707; padding:5px; text-align:center; border:1px solid #cfcfcf;"';
            string tdRed = '"background-color:#FFF6D5; color:#E80707; padding:5px; text-align:right; font-weight:bold; border:1px solid #cfcfcf;"';
            //Building Html body of email
            string htmlBody ='<p style="font-size: small">Dear '+u.FirstName+',</p>'+
                '<div><p>'+
                'This is a weekly reminder for you to review the tasks listed above.'+
                'The tasks are raised in Panorama by the Product Marketing Teams, and they are waiting for your feedback. We kindly request that all necessary actions are taken promptly and efficiently.'+
                '<div style="max-height:430px; overflow:auto; margin-top:10px; border-radius:0.25rem;">' +
                '<div role="region" aria-labelledby="HeadersCol" tabindex="0" class="rowheaders">' +
                '<table class="maintable fixedtable" style="border-collapse:collapse;min-width: 75%;">' +
                
                // Table Header with sub-columns
                '<thead>' +
                '<tr>' +
                '<th scope="col" rowspan="2" style=' + td1 + '>Task Type</th>' +
                '<th scope="col" colspan="2" style=' + td1 + '>Total Assigned</th>' +
                '<th scope="col" colspan="2" style=' + td1 + '>Total Completed</th>' +
                '<th scope="col" colspan="2" style=' + td1 + '>Total Pending</th>' +
                '</tr>' +
                '<tr>' +
                '<th style=' + td1 + '>Tasks</th>' +
                '<th style=' + td1 + '>Value</th>' +
                '<th style=' + td1 + '>Tasks</th>' +
                '<th style=' + td1 + '>Value</th>' +
                '<th style=' + td1 + '>Tasks</th>' +
                '<th style=' + td1 + '>Value</th>' +
                '</tr>' +
                '</thead>' +
                
                // Table Body
                '<tbody>' +
                
                // Compliance row
                '<tr>' +
                '<td style=' + td2 + '>Compliance</td>' +
                '<td style=' + td2 + '>'+compAssigned1+'</td>' +
                '<td style=' + td2 + '>$'+compAssignedAmt.format()+'</td>' +
                '<td style=' + tdGreen + '>'+compCompleted+'</td>' +
                '<td style=' + tdGreen + '>$'+compCompletedAmt.format()+'</td>' +
                '<td style=' + tdYellow + '>'+comppending+'</td>' +
                '<td style=' + tdYellow + '>$'+comppendingAmt.format()+'</td>' +
                '</tr>' +
                
                // Cross Sell row
                '<tr>' +
                '<td style=' + td2 + '>Cross Sell</td>' +
                '<td style=' + td2 + '>'+crossAssigned+'</td>' +
                '<td style=' + td2 + '>$'+crossAssignedAmt.format()+'</td>' +
                '<td style=' + tdGreen + '>'+crossCompleted+'</td>' +
                '<td style=' + tdGreen + '>$'+crossCompletedAmt.format()+'</td>' +
                '<td style=' + tdYellow + '>'+crossPending+'</td>' +
                '<td style=' + tdYellow + '>$'+crossPendingAmt.format()+'</td>' +
                '</tr>' +
                
                // Winback row
                '<tr>' +
                '<td style=' + td2 + '>Winback</td>' +
                '<td style=' + td2 + '>'+winAssigned+'</td>' +
                '<td style=' + td2 + '>$'+winAssignedAmt.format()+'</td>' +
                '<td style=' + tdGreen + '>'+winCompleted+'</td>' +
                '<td style=' + tdGreen + '>$'+winCompletedAmt.format()+'</td>' +
                '<td style=' + tdYellow + '>'+winPending+'</td>' +
                '<td style=' + tdYellow + '>$'+winPendingAmt.format()+'</td>' +
                '</tr>' +
                
                '</tbody>' +
                '</table></div></div>'
                +'<p>Please <a href='+UrlList+'>Click here</a> to view All Tasks.</p>'+
                ' <p style="font-size: small"> Best Regards,<br>Bright Support Team</br> </p>'+
                '<p style="font-size: 12px; font-style: italic; color: #333;">'+
                '[This is an auto-generated mail from BRIGHT, please do not reply to this email. If you need assistance or wish to report an issue, kindly submit a ticket through TechEase.]</p>';
            
            mail.setHtmlBody(htmlBody);
            mails.add(mail);
        }  
        Messaging.sendEmail(mails); 
   }
    
    public void finish(Database.BatchableContext bc){
        
    }
    global void execute(SchedulableContext SC) {
        TaskReminderEmailBatch task = new TaskReminderEmailBatch(); 
    }
    
}