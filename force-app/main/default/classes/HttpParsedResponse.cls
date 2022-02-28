public class HttpParsedResponse {

    public String responseBody {
        get {

            if( responseBody == null ){
                responseBody = '{}';
            }
            
            return responseBody;
        }
        set;
    }

    public HttpResponseError[] errors {
        get {

            if( errors == null ){
                errors = new HttpResponseError[]{};
            }

            return errors;
        }
        set;
    }
}