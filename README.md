# wkhtmltopdf (A CFML/Coldbox Wrapper)
After years of wrestling with cfdocument from Adobe and Lucee, we centralized our "convert this to PDF" functions using a wkhtmltopdf Docker container based on this repository:

https://github.com/MotorsportReg/docker-wkhtmltopdf-service

All this module does is provide a friendly interface to the API for that service. **This module does not contain the wkhtmltopdf utility or do any conversion by itself**. You must be running wkhtmltopdf as a service for this module to do any good. 

## A note on wkhtmltopdf (it's obsolete)

The [wkhtmltopdf library](https://github.com/wkhtmltopdf/wkhtmltopdf) is deprecated due to its reliance on the QT rendering library. The only way that wkhtmltopdf should ever be used is in an isolated web service with no access to the Internet. There are newer HTML to PDF services out there. This library is strictly for apps that rely on the 'it just works' aspect of wkhtmltopdf.

### So why does this module exist?

This module just wraps a web service that expects HTML and produces a PDF. It could very easily wrap a different web service aside from wkhtmlpdf. PRs accepted!

### Inspiration 
While Coldbox's `renderData()` convention makes it very easy to convert anything to PDF (or JSON, XML, or HTML), you're at the mercy of the application engine's PDF library -- and you have to include the PDF extension in your deployment (for Lucee) or the Adobe PDF Service (for ACF). 

The wkhtmltopdf module was inspired by Ryan Guill's recommendation of the above docker-wkhtmltopdf-service on the CFML Slack (and some sample code, included at the end of this README)

A simple request to wkhtmltopdf, whether you're executing it locally or using an API to a Docker container, doesn't need even a small module -- cfhttp will do the job. But if you're making these requests all over your application, it's nice to centralize common settings and the relevant code. For more complicated PDFs with multiple sources (or sources combined from URLs and strings), we enjoy even more benefit from re-using code. We also wanted to memorialize Ryan's recommendation for a wonderful and simple Docker "edition" of wkhtmltopdf and centralize our settings for the hostname, port, and TLS status of the wkhtmltopdf service.

## Requirements:
* Supported Engines: Lucee 5+, Adobe Coldfusion 11+
* a wkhtmltopdf service accessible to your CF engine
* Coldbox. It would not take much doing to re-write the module without Wirebox or Hyper ... but just use Coldbox.

## Usage

Instantiate the PDF Service:

`property name="PDFService" inject="PDFService@wkhtmltopdf";`

or

`PDFService = wirebox.getInstance( "PDFService@wkhtmltopdf" );`

### Converting a single content string

For simple requests where you have the source HTML available in one variable or accessible via a single URL, use the `toPDF` function:

#### `toPDF`

| Name        | Type   | Required | Default | Description                                                    |
| ----------- | ------ | -------- | ------- | -------------------------------------------------------------- |
| content     | string | true     | null    | HTML to be converted to PDF, or a valid URL                    |
| output      | string | false    | pdf     | Desired output type (pdf, png, or jpg).                        |
| options     | struct | false    | null    | An optional struct of wkhtmltopdf parameters for the request.  |

Example:
```
var myPDF = PDFService.toPDF(
  content = '<html><head><title>A Sample PDF</title></head><body><p>Some Sample Content</p></body></html>'
);
```

### Converting multiple sources: The PDF Request Object

If you want to build a PDF from multiple source strings, multiple URLs, or a combination of both, you can build an array of `PDFRequest` objects. Each PDFRequest is very similar to a `toPDF()` call; it contains the data relevant to a single source (whether a string or a URL) and whatever options and/or cookies apply to that request. Keep in mind that each request object needs its own set of options, even if you are re-using the same options across all requests!

First, create one or more PDFRequest objects using the convenience method `toPDFRequest()`. Then, send the array of PDFRequests to `toPDFMultiple()`.

#### `toPDFRequest`

| Name        | Type   | Required | Default | Description                                                                                              |
| ----------- | ------ | -------- | ------- | -------------------------------------------------------------------------------------------------------- |
| content     | string | true     | null    | HTML to be converted to PDF, or a valid URL                                                              |
| isURL       | booelan| false    | null    | Indicate whether `content` is a string to be converted or a URL. Uses `isValid( "url")` if not provided. |
| options     | struct | false    | null    | An optional struct of wkhtmltopdf parameters for the request.                                            |
| cookies     | struct | false    | null    | An optional struct of cookies to pass to wkhtmltopdf.                                                    |

#### `toPDFMultiple`

| Name        | Type   | Required | Default | Description                                                    |
| ----------- | ------ | -------- | ------- | -------------------------------------------------------------- |
| requests    | array  | true     | null    | Array of PDFRequest objects (from `toPDFRequest()`)            |
| output      | string | false    | pdf     | Desired output type (pdf, png, or jpg).                        |

Example:

```
  var pdfRequest = PDFService.toPDFRequest(
    content = 'https://www.google.com',
    options = {
      'grayscale' = true
    }
  );

  var pdfRequest2 = PDFService.toPDFRequest(
    content = '<html><head><title>A Document</title></head><body><p>Some text</p></body></html>'
  );

   var pdfResult = PDFService.toPDFMultiple( requests =  [ pdfRequest, pdfRequest2 ] );
```

### The options struct

Every request to wkhtmltopdf supports an **options** struct whose values are passed to the wkhtmltopdf binary. Future versions of this module may list and validate these options directly, but for now, CF will pass whatever options you specify to wkhtmltopdf without validating whether the options exist or the value specified is supported.  Available options are listed in the [wkhtmltopdf documentation](https://wkhtmltopdf.org/usage/wkhtmltopdf.txt) but note that image return types do not support all options.

### Rendering the Result

PDFService returns a binary object. We can still take advantage of `renderData()` but we just won't ask it to do the conversion. Since PDFService gives us a binary object, here's how we would display the **myPDF** object above in a handler event:
```
     return event.renderData( 
       data = myPDF,
       isBinary = true,
       contentType = "application/pdf"
     );
```

Alternatively, you could call `cfcontent` directly with a MIME-type of `application/pdf`. `renderData()` does this for us and also adds appropriate headers for content-length.

### Error Handling

There is specific handling for timeouts (504) if Hyper tries to reach wkhtmltopdf and can't. By default, it will try once with a timeout of 10 seconds. On occasion, if you are sending large chunks of content to wkhtmltopdf, you might want to retry the HTTP call. The `retries` and `timeout` arguments to `toPDF()` and `toPDFMultiple()` allow you to override the default behavior of '0 retries, 10 second timeout.'

If PDFService gets anything other than a `200 OK` from wkhtmltopdf, either because it can't connect or the wkhtmltopdf service returns an error code, it will throw an exception along with the HTTP Status code from the attempted connection to wkhtmltopdf. 

### But I don't have Coldbox!

This module relies on Coldbox and Wirebox to simplify some of the more complex use cases, like asking for multiple source documents, or mixed URL and content requests. If you aren't using Coldbox in your app, you can still take advantage of wkhtmltopdf -- just not with this module. Start with Ryan's sample code (converted to cfscript)
```
public binary function printPDF(
  required string html,
  struct options = {}
) {
  var args = {
    "output" : "pdf",
    "request" [
      {
        "content" : arguments.html,
        "options" : arguments.options
      }
    ]
  };
  
  cfhttp(
    url = "URLtoMywkhtmltopdfService",
    method = "POST",
    result = "local.httpResult",
    throwonerror = true
  ) {
    cfhttpparam( type="body" value = serializeJSON( args ) );
  }
  
  return httpResult.fileContent.toByteArray();
}
  ```

