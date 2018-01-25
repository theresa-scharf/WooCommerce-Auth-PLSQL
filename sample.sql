DECLARE
    l_client_url CONSTANT VARCHAR2(1000) := 'http://your_store_url_here.com';
    l_api CONSTANT VARCHAR2(1000) := 'wp-json/wc/v2';
    l_http_method VARCHAR2(50) := 'GET';
    l_endpoint VARCHAR2(50) := 'orders';
    l_ck VARCHAR2(1000) := 'your_consumer_key_here';
    l_cs VARCHAR2(1000) := 'your_consumer_secret_here';
    l_exe_url VARCHAR2(32767);

    l_request UTL_HTTP.req;
    l_response UTL_HTTP.resp;
BEGIN
    l_exe_url :=
        oauth_url(l_http_method
                 ,l_client_url || '/' || l_api || '/' || l_endpoint
                 ,l_ck
                 ,l_cs);

    l_request := sys.UTL_HTTP.begin_request(l_exe_url, l_http_method, UTL_HTTP.http_version_1_1);
    l_response := sys.UTL_HTTP.get_response(l_request);

    IF l_response.status_code IS NULL
       OR l_response.status_code != 200 THEN
        DBMS_OUTPUT.put_line(
               'FAILURE, Bad Response:'
            || l_response.status_code
            || ' Reason: '
            || l_response.reason_phrase);
    ELSE
        DBMS_OUTPUT.put_line('PASSED, Status Code 200 :)');
    END IF;
END;