/**
 * File: PDFRequest.cfc
 * Author: Samuel Knowlton <sam@inleague.io>
 * Date: January 3, 2020
 * Description: A single request object to be sent to the wkhtmltopdf service. Gets transformed into an element in the 'requests' array described here: https://github.com/MotorsportReg/docker-wkhtmltopdf-service
 */

component accessors=true {
    
    property name="wirebox" inject="wirebox";

    // isURL: if true, forms a 'url' request. if false, forms a 'content' request. Dynamically determined if it isn't specified.
    property name="isURL" type="boolean"; 
    
    // content: html content to be converted, or else URL 
    property name="content" type="string"; // 

    // options: optional key-value arguments passed on to the wkhtmltopdf binary. See the docker-wkhtmltopdf-service repo for a list
    property name="options" type="struct";

    // cookies: optional key-value arguments passed on to the wkhtmltopdf binary as separate 'cookie' arguments.
    property name="cookies" type="struct";

    /**
     * Init
     * @wirebox.inject wirebox
    */

    public function init(
        wirebox,
        boolean isURL,
        string content = '',
        struct options = {},
        struct cookies = {}
    ) {    

        wirebox.getObjectPopulator().populateFromStruct( target = this, memento = arguments );

        if ( !structKeyExists( arguments, 'isURL' ) ) {
            this.setISURL( isValid( 'url', arguments.content ) );
        }

        return this;
    }

    /**
     * toWkhtmltopdfRequest
     * @hint Simple transformer (sorry, cffractal) that produces the struct we'll insert into the "requests" array in the wkhtmltopdf request
    */
    
    public struct function toWkhtmltopdfRequest() {
        
        var requestStruct = {};

        if ( this.getIsURL() ) {
            local.requestStruct[ "url" ] = this.getContent();
        }
        else { 
            local.requestStruct[ "content" ] = this.getContent()
        };

        if ( this.getOptions().len() ) {
            local.requestStruct[ "options" ]  = this.getOptions();
        }

        if ( this.getCookies().len() ) {
            local.requestStruct[ "cookies" ]  = this.getCookies();
        }

        return local.requestStruct;
        
    }
}