CREATE OR REPLACE FUNCTION oauth_url(http_method_in VARCHAR2
                                    ,full_url_in VARCHAR2
                                    ,consumer_key_in VARCHAR2
                                    ,consumer_secret_in VARCHAR2)
    RETURN VARCHAR2
IS
    l_time_stamp VARCHAR(1000);
    l_nonce VARCHAR2(1000);
    l_params VARCHAR2(1000);
    l_sig_base VARCHAR2(1000);
    l_sig_full VARCHAR2(1000);
    l_return_url VARCHAR2(32767);

    FUNCTION url_encode(str_in IN VARCHAR2) /*startfold*/
        RETURN VARCHAR2
    AS
        l_ret_val VARCHAR2(4000);
        l_bad VARCHAR2(100) DEFAULT ' >%}\~];?@&<#{|^[`/:=$+''"';
        l_char CHAR(1);
    BEGIN
        FOR i IN 1 .. NVL(LENGTH(str_in), 0)
        LOOP
            l_char := SUBSTR(str_in, i, 1);
            IF (INSTR(l_bad, l_char) > 0) THEN
                l_ret_val := l_ret_val || '%' || TO_CHAR(ASCII(l_char), 'fmXX');
            ELSE
                l_ret_val := l_ret_val || l_char;
            END IF;
        END LOOP;
        RETURN l_ret_val;
    END url_encode; /*endfold*/

    FUNCTION generate_timestamp /*startfold*/
        RETURN VARCHAR2
    AS
        l_timestamp VARCHAR2(1000);
    BEGIN
        l_timestamp :=
            ROUND(
                (CAST((SYSTIMESTAMP AT TIME ZONE 'GMT') AS DATE)
                 - TO_DATE('01-01-1970', 'DD-MM-YYYY'))
                * (86400)
               ,0);
        RETURN l_timestamp;
    END generate_timestamp; /*endfold*/

    FUNCTION generate_nonce /*startfold*/
        RETURN VARCHAR2
    AS
        l_gen_nonce VARCHAR2(1000);
    BEGIN
        l_gen_nonce := DBMS_RANDOM.string('A', 15);
        l_gen_nonce := UTL_ENCODE.base64_encode(UTL_I18N.string_to_raw(l_gen_nonce, 'AL32UTF8'));
        RETURN l_gen_nonce;
    END generate_nonce; /*endfold*/

    FUNCTION generate_signature(url_in VARCHAR2, key_in VARCHAR2) /*startfold*/
        RETURN VARCHAR2
    AS
        l_sig_raw RAW(5000);
        l_sig_var VARCHAR2(5000);
    BEGIN
        l_sig_raw :=
            DBMS_CRYPTO.mac(src => UTL_I18N.string_to_raw(url_in, 'AL32UTF8')
                           ,typ => DBMS_CRYPTO.hmac_sh1
                           ,key => UTL_I18N.string_to_raw(key_in, 'AL32UTF8'));

        l_sig_var := UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(l_sig_raw));
        RETURN l_sig_var;
    END generate_signature; /*endfold*/
BEGIN
    l_sig_base := UPPER(http_method_in) || '&' || url_encode(full_url_in);
    l_time_stamp := generate_timestamp;
    l_nonce := generate_nonce;
    l_params :=
           'oauth_consumer_key='
        || consumer_key_in
        || '&oauth_nonce='
        || l_nonce
        || '&oauth_signature_method=HMAC-SHA1'
        || '&oauth_timestamp='
        || l_time_stamp;

    l_sig_full :=
        generate_signature(l_sig_base || '&' || url_encode(l_params), consumer_secret_in || '&');
    l_return_url := full_url_in || '?' || l_params || '&oauth_signature=' || l_sig_full;
    RETURN l_return_url;
END oauth_url;