public abstract class HttpHandler {


    public HttpRequest request {get;set;}
    
    public HttpResponse response {get;set;}

    protected HttpParsedResponse parsedResponse {
        get {
            
            if( parsedResponse == null ){
                parsedResponse = new HttpParsedResponse();
            }
            
            return parsedResponse;
        }
        set;
    }

    public abstract String getEndpoint();
    public abstract String getMethod();

    public void send( HttpRequest request ){
        this.request = request;

        request.setEndpoint( getEndpoint() );
        request.setMethod( getMethod() );

        Http http = new Http();

        response = http.send( request );

        parseResponse();
    }

    public void parseResponse(){
        parsedResponse.responseBody = response.getBody();

        if( response.getStatusCode() > 299 ){
            parseErrors();
        }
    }
    
    public void parseErrors(){
        HttpResponseError error = new HttpResponseError();
        error.errorMessage = getErrorMessage();
        error.statusCode = response.getStatusCode();
        error.status = response.getStatus();
        
        parsedResponse.errors.add( error );
    }

    public void checkErrors(){
        if( hasErrors() ){
            throw new InvocableException( JSON.serialize( getErrors() ) );
        }
    }

    public Boolean hasErrors(){
        return parsedResponse.errors.size() > 0;
    }

    public HttpResponseError[] getErrors(){
        return parsedResponse.errors;
    }

    public virtual String getErrorMessage(){
        return 'An Error has occured. This is the HttpHandler default error message.';
    }

    class InvocableException extends Exception {}
}