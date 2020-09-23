@isTest
private class AttachmentTrigger_Test {
    @isTest()
    static void EmailMessageTrigger_Test_test1() {
        Case c = new Case(subject = 'test');
        insert c;
        EmailMessage newemail = new Emailmessage(Subject = '識別子/チャンネル名',PARENTID = c.id);//識別子とチャンネル名部分は任意
        insert newemail;
        StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'addPlatform' LIMIT 1];
        Attachment newAT = new Attachment(Name = 'Attachment_2.jpeg',Parentid = newemail.id,CONTENTTYPE = 'image/jpeg',body = sr.body);
        Test.setMock(HttpCalloutMock.class, new HTTPRequestMock_GoogleCalendar(false));
        Test.startTest();
        insert newAT;
        Test.stopTest();
    }
}
