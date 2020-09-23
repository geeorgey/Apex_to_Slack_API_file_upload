public with sharing class AttachmentTriggerHandler {

    public void onAfterInsert(LIST<Attachment> Attachmentew) {
        config_vars__mdt[] configMappings = [SELECT MasterLabel, QualifiedApiName, value__c FROM config_vars__mdt];//カスタムメタデータ型を取得
        
        Integer triggersize = Attachmentew.size();
        system.debug('triggersize ' + triggersize);
        LIST<Event>updateEvents = new LIST<Event>();
        for(Integer i = 0;i<triggersize;i++){
            if(Attachmentew[i].CONTENTTYPE.contains('image')){//画像ファイルの時に処理
                List<EmailMessage>thisEmail = new List<EmailMessage>();
                system.debug('Query SELECT subject FROM EmailMessage WHERE Parentid = ' + Attachmentew[i].Parentid + ' LIMIT 1');
                thisEmail = [SELECT subject FROM EmailMessage WHERE id = :Attachmentew[i].Parentid LIMIT 1];
                if(thisEmail.size()>0){
                    if(thisEmail[0].subject.contains('識別子')){
                        LIST<String>args = thisEmail[0].subject.split('/');//メールのsubjectを１５行目の識別子(任意)/チャンネル名という形式にして送信する
                        system.debug('args: ' + args);
                        String channel = '';
                        if(args.size()>0){
                            channel = args[1];//チャンネル名を取得
                            system.debug('channel : ' + channel);
                        }

                        String channeiID = '';
                        String bottoken = '';                
                        for (config_vars__mdt configMapping : configMappings) {
                            if(configMapping.MasterLabel == channel){
                                channeiID = configMapping.value__c;
                            }else if(configMapping.MasterLabel == 'SlackBot_uploader'){
                                bottoken = configMapping.value__c;
                            }
                        }

                        //参考：https://blog.freedom-man.com/apex-multipartform-data
                        String boundary = 'boundary';
                        String header = '--'+boundary+'\r\nContent-Disposition: form-data;name="file";'+
                            'filename="'+ Attachmentew[i].name + '";\n'+ 
                            'Content-Type: ' + Attachmentew[i].ContentType;
                        send('https://slack.com/api/files.upload?channels=' + channeiID, header, boundary, Attachmentew[i].body,bottoken);
                    }
                }
            }
        }
    }


    @Future(callout=true)
    public static void send(String reqEndpoint, String header, String boundary, Blob blobBody,String bottoken) {
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + bottoken);
        req.setHeader('Content-Type','multipart/form-data; boundary=' + boundary);
        req.setMethod('POST');
        req.setEndpoint(reqEndPoint);
        req.setBodyAsBlob(getMultiPartBody(header, boundary, blobBody));
        req.setTimeout(120000);
 
        Http http = new Http();
            HTTPResponse res = http.send(req);
            system.debug('res : ' + res.getBody());
            //return res.getBody();
    }

    public static Blob getMultiPartBody(String header, String boundary, Blob file_body){
        String footer = '--'+boundary+'--';             
        String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
        while(headerEncoded.endsWith('=')){
            header+=' ';
            headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
        }
        String bodyEncoded = EncodingUtil.base64Encode(file_body);
      
        Blob bodyBlob = null;
        String last4Bytes = bodyEncoded.substring(bodyEncoded.length()-4,bodyEncoded.length());
 
        if(last4Bytes.endsWith('==')) {
            last4Bytes = last4Bytes.substring(0,2) + '0K';
            bodyEncoded = bodyEncoded.substring(0,bodyEncoded.length()-4) + last4Bytes;
            // We have appended the \r\n to the Blob, so leave footer as it is.
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);
        } else if(last4Bytes.endsWith('=')) {
            last4Bytes = last4Bytes.substring(0,3) + 'N';
            bodyEncoded = bodyEncoded.substring(0,bodyEncoded.length()-4) + last4Bytes;
            // We have appended the CR e.g. \r, still need to prepend the line feed to the footer
            footer = '\n' + footer;
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);              
        } else {
            // Prepend the CR LF to the footer
            footer = '\r\n' + footer;
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);  
        }
        return bodyBlob;
    }
}
