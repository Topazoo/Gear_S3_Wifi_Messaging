#include <tizen.h>
#include <http.h>
#include <stdio.h>
#include <stdlib.h>
#include "watch_sample.h"

#define TEXT_BUF_SIZE 256

/* -------- Server Info Data Structures  -------- */
typedef struct server {
	char* url;  // Server url
	char* token; // CSRF token

	http_session_h session; // HTTP session for POST
	http_transaction_h transaction; // HTTP transaction for POST

} server_s;

server_s* init_server(const char* server_url)
{
	/* Initialize and return a server struct */

	server_s* server = malloc(sizeof(server_s));

	server->session = NULL;
	server->transaction = NULL;

	/* Allow for dynamic URL */
	server->url = malloc(strlen(server_url) * sizeof(char) + sizeof(char));
	strcpy(server->url, server_url);

	server->token = malloc(1024 * sizeof(char)); // TODO - Make dynamic

	return server;
}

void deinit_server(server_s* server)
{
	/* Deinitialize a server struct */

	/* Destroy transactions and session */
	http_session_destroy_all_transactions(server->session);
	http_session_destroy(server->session);

	/* Free memory */
	free(server->url);
	free(server->token);
	free(server);
}
/* -------------------------------------------- */


/* ---------- Message Data Structures --------- */
typedef struct message {
	char to_address[20];
	char from_address[20];
	char message_body[TEXT_BUF_SIZE * 2];

} message_s;

message_s* create_message(char* to_number, char* from_number, char* message)
{
	/* Create a message object from passed info */

	message_s* new_message = malloc(sizeof(message_s));

	/* Set the number the message is being sent to */
	strcpy(new_message->to_address, to_number);
	/* Set the number the message is being sent from */
	strcpy(new_message->from_address, from_number);
	/* Set the message being sent */
	strcpy(new_message->message_body, message);

	return new_message;
}
/* -------------------------------------------- */


/* -------------- UI and watch data ----------- */
typedef struct appdata {
	Evas_Object *win;
	Evas_Object *conform;
	Evas_Object *label;

	server_s* server; // Server data
	message_s* message; // Message to send
	volatile int sent;

} appdata_s;
/* -------------------------------------------- */


char* parse_CSRF_token(char* body)
{
	/* Parse the CSRF token */

	char* token_loc;
	char* end;

	if(body == NULL)
		return body;

	/* Find in the full text of the page body */
	token_loc = strstr(body, "csrfmiddlewaretoken");

	if(token_loc == NULL)
		return NULL;

	/* Move to start of token text and copy over chunk */
	token_loc += 28;

	/* Find end of token and cleave end of chunk */
	end = strstr(token_loc,"\'"); *end = '\0';

	return token_loc;
}

void get_CSRF_token(server_s* server)
{
	/* Set CSRF token from server via callback */

	int code;

	code = http_transaction_submit(server->transaction);
	if(code == HTTP_ERROR_NONE)
		dlog_print(DLOG_DEBUG, "GET", "Transaction sent!");
	else
	{
		dlog_print(DLOG_DEBUG, "GET", "Failed to send transaction, error %d", code);
		return;
	}

}

/* ---------- Transaction Callbacks ----------- */
void got_header_callback(http_transaction_h transaction, char* header, size_t length, void* data)
{
	/* Get and store HTTP header data */

	dlog_print(DLOG_DEBUG, "HEADER", "Got Header", header);
}

void got_body_callback(http_transaction_h transaction, char* body, size_t length, size_t nmemb, void* data)
{
	/* Get and store HTTP body data */

	char* token = parse_CSRF_token(body);
	server_s* server = (server_s*) data;

	if(token)
	{
		strcpy(server->token, token);
		dlog_print(DLOG_DEBUG, "Token", "Got token %s of length %d in body callback", server->token, strlen(server->token));
	}
	else
	{
		dlog_print(DLOG_DEBUG, "Token", "No token found");
		return;
	}

	dlog_print(DLOG_DEBUG, "BODY", "Got body");
}
/* -------------------------------------------- */

void set_transaction_headers(http_transaction_h transaction, const char* msg, char* csrf)
{
	/* Set HTTP headers required for a POST transaction */
	char msg_length_buffer[5];

	/* Set content type and length */
	http_transaction_header_add_field(transaction, "Content-Type", "application/x-www-form-urlencoded");
	sprintf(msg_length_buffer, "%d", strlen(msg));
	http_transaction_header_add_field(transaction, "Content-Length", msg_length_buffer);

	/* Set User Agent */
	http_transaction_header_add_field(transaction, "HTTP-User-Agent", "Mozilla/5.0 (Linux; Tizen Wearable 4.0; SAMSUNG GEAR S3) AppleWebKit/537.3 (KHTML, like Gecko) Version/2.2 like Android 4.1; Mobile Safari/537.3");

	/* Set CSRF token */
	http_transaction_header_add_field(transaction, "CSRF-Cookie", csrf);
}

char* build_query_string(message_s* message, char* csrf)
{
	/* Build message into server query */

	char* query = malloc(sizeof(char) * (TEXT_BUF_SIZE * 3));
	strcpy(query, "message=");
	strcat(query, message->message_body);
	strcat(query, "&to_number=");
	strcat(query, message->to_address);
	strcat(query, "&from_number=");
	strcat(query, message->from_address);
	strcat(query, "&csrfmiddlewaretoken=");
	strcat(query, csrf);

	dlog_print(DLOG_DEBUG, "MESSAGE", "Query string %s", query);

	return query;
}

int send_message(appdata_s* ad)
{
	/* Send message data from client (watch) to server */

	int code;
	char* csrf = "1234"; // TODO - Get and set real CSRF

	char* to_number = "4152094084";
	char* from_number = "4152094084";
	char* input = "Hello from client!"; //TODO - Get input from watch

	/* Get the message being sent */
	message_s* message_struct = create_message(to_number, from_number, input); //TODO - Create messages in button callback
	ad->message = message_struct;
	/* Turn message into query */
	const char* message = build_query_string(message_struct, csrf);

	/* Set headers required to POST to Django server */
	set_transaction_headers(ad->server->transaction, message, csrf);

	/* Get ready to write message */
	code = http_transaction_set_ready_to_write(ad->server->transaction, 1);
	if(code == HTTP_ERROR_NONE)
		dlog_print(DLOG_DEBUG, "WRITE", "Ready to write!");
	else
	{
		dlog_print(DLOG_DEBUG, "WRITE", "Failed to get ready to write - error %d", code);
		return -1;
	}

	/* Write message */
	code = http_transaction_request_write_body(ad->server->transaction, message);
	if(code == HTTP_ERROR_NONE)
		dlog_print(DLOG_DEBUG, "WRITE", "Wrote %s to transaction", message);
	else
	{
		dlog_print(DLOG_DEBUG, "WRITE", "Failed to write - error %d", code);
		return -2;
	}

	/* Submit POST transaction */
	code = http_transaction_submit(ad->server->transaction);
	if(code == HTTP_ERROR_NONE)
		dlog_print(DLOG_DEBUG, "POST", "Transaction sent!");
	else
	{
		dlog_print(DLOG_DEBUG, "POST", "Failed to send transaction - error %d", code);
		return -3;
	}

	return 0;
}

int ready_transaction(server_s* server, http_method_e method)
{
	/* Set callbacks for transactions */

	int code;

	/* Prepare for HTTP transactions */
	code = http_session_open_transaction(server->session, method, &(server->transaction));
	if(code == HTTP_ERROR_NONE)
		dlog_print(DLOG_DEBUG, "POST", "HTTP transaction opened");
	else
	{
		dlog_print(DLOG_DEBUG, "POST", "Failed to open transaction - error %d", code);
		return -1;
	}

	/* Set transaction URL */
	code = http_transaction_request_set_uri(server->transaction, server->url);
	if(code == HTTP_ERROR_NONE)
		dlog_print(DLOG_DEBUG, "POST", "Transaction URL set to %s", server->url);
	else
	{
		dlog_print(DLOG_DEBUG, "POST", "Failed to set transaction URL - error %d", code);
		return -2;
	}

	/* Set transaction method */
	code = http_transaction_request_set_method(server->transaction, method);
	if(code == HTTP_ERROR_NONE)
		dlog_print(DLOG_DEBUG, "POST", "Transaction method set");
	else
	{
		dlog_print(DLOG_DEBUG, "POST", "Failed to set transaction method - error %d", code);
		return -3;
	}

	/* Set HTTP Version */
	code = http_transaction_request_set_version(server->transaction, HTTP_VERSION_1_0);
	if(code == HTTP_ERROR_NONE)
		dlog_print(DLOG_DEBUG, "HTTP", "Version set");
	else
	{
		dlog_print(DLOG_DEBUG, "HTTP", "Failed to set version - error %d", code);
		return -4;
	}

	/* Set callback for when header information is received */
	http_transaction_set_received_header_cb(server->transaction, got_header_callback, server);
	/* Set callback for when body information is received */
	http_transaction_set_received_body_cb(server->transaction, got_body_callback, server);

	if(method == HTTP_METHOD_POST)
		dlog_print(DLOG_DEBUG, "TRANSACTION", "POST transaction is good to go!");
	else if(method == HTTP_METHOD_GET)
		dlog_print(DLOG_DEBUG, "TRANSACTION", "GET transaction is good to go!");

	return 0;
}

int initialize_HTTP(appdata_s* ad)
{
	/* Set up HTTP for client */
	bool auto_redirect = true;

	/* Initialize HTTP functionality */
	int code = http_init();
	if (code != HTTP_ERROR_NONE)
	{
		dlog_print(DLOG_DEBUG, "HTTP Initialization", "HTTP initialization failed - error %d", code);
		return -1;
	}

	/* Initialize  HTTP session */
	code = http_session_create(HTTP_SESSION_MODE_NORMAL, &(ad->server->session));
	if (code != HTTP_ERROR_NONE)
	{
		dlog_print(DLOG_DEBUG, "HTTP Session", "HTTP session failed - error %d", code);
		return -2;
	}

	/* Automatically redirect connections */
	code = http_session_set_auto_redirection(ad->server->session, auto_redirect);
	if (code != HTTP_ERROR_NONE)
	{
		dlog_print(DLOG_DEBUG, "HTTP Redirect", "HTTP Redirect failed - error %d", code);
		return -3;
	}

	return 0;
}

static void deinitialize_HTTP(appdata_s* ad)
{
	/* Clean up HTTP functionality */

	/* Deinitialize HTTP */
	int code = http_deinit();

	if (code == HTTP_ERROR_NONE) // DEBUG
		dlog_print(DLOG_DEBUG, "HTTP Deinitialization", "HTTP deinitialized.");
	else
		dlog_print(DLOG_DEBUG, "HTTP Deinitialization", "HTTP deinitialization failed.");
}

static void
update_watch(appdata_s *ad)
{
	char watch_text[TEXT_BUF_SIZE];
	int error_code = -1;

	/* Send POST to server */
	if(ad->sent == 0)
	{
		error_code = send_message(ad);
		ad->sent = 1;
	}
	if(error_code == 0)
		dlog_print(DLOG_DEBUG, "POST", "Transaction sent successfully!");

	snprintf(watch_text, TEXT_BUF_SIZE, "<align=center>\"%s\"</align>", ad->message->message_body);

	elm_object_text_set(ad->label, watch_text);
}

static void
create_base_gui(appdata_s *ad, int width, int height)
{
	int ret;
	watch_time_h watch_time = NULL;

	/* Window */
	ret = watch_app_get_elm_win(&ad->win);
	if (ret != APP_ERROR_NONE) {
		dlog_print(DLOG_ERROR, LOG_TAG, "failed to get window. err = %d", ret);
		return;
	}

	evas_object_resize(ad->win, width, height);

	/* Conformant */
	ad->conform = elm_conformant_add(ad->win);
	evas_object_size_hint_weight_set(ad->conform, EVAS_HINT_EXPAND, EVAS_HINT_EXPAND);
	elm_win_resize_object_add(ad->win, ad->conform);
	evas_object_show(ad->conform);

	/* Label*/
	ad->label = elm_label_add(ad->conform);
	evas_object_resize(ad->label, width, height / 3);
	evas_object_move(ad->label, 0, height / 3);
	evas_object_show(ad->label);

	ret = watch_time_get_current_time(&watch_time);
	if (ret != APP_ERROR_NONE)
		dlog_print(DLOG_ERROR, LOG_TAG, "failed to get current time. err = %d", ret);

	update_watch(ad);
	watch_time_delete(watch_time);

	/* Show window after base gui is set up */
	evas_object_show(ad->win);
}

static bool
app_create(int width, int height, void *data)
{
	/* Hook to take necessary actions before main event loop starts
		Initialize UI resources and application's data
		If this function returns true, the main loop of application starts
		If this function returns false, the application is terminated */

	int error_code = 0;
	appdata_s *ad = data;

	/* Create server data structure with restpoint URL */
	ad->server = init_server("http://52.25.144.62/");

	/* Configure client for HTTP POST */
	error_code = initialize_HTTP(ad);
	if(error_code == 0)
		dlog_print(DLOG_DEBUG, "HTTP", "HTTP is good to go!");

	// TODO - Get and set CSRF token

	/* Get ready for POST transaction */
	error_code = ready_transaction(ad->server, HTTP_METHOD_POST);
	if(error_code == 0)
		dlog_print(DLOG_DEBUG, "POST", "Transaction is good to go!");

	create_base_gui(ad, width, height);

	return true;
}

static void
app_control(app_control_h app_control, void *data)
{
	/* Handle the launch request. */
}

static void
app_pause(void *data)
{
	/* Take necessary actions when application becomes invisible. */
}

static void
app_resume(void *data)
{
	/* Take necessary actions when application becomes visible. */
}

static void
app_terminate(void *data)
{
	/* Release all resources. */

	appdata_s *ad = data;

	deinitialize_HTTP(ad);
	deinit_server(ad->server);

	free(ad->message);
}

static void
app_time_tick(watch_time_h watch_time, void *data)
{
	/* Called at each second while your app is visible. Update watch UI. */
	appdata_s *ad = data;
	update_watch(ad);
}

static void
app_ambient_tick(watch_time_h watch_time, void *data)
{
	/* Called at each minute while the device is in ambient mode. Update watch UI. */
	appdata_s *ad = data;
	update_watch(ad);
}

static void
app_ambient_changed(bool ambient_mode, void *data)
{
	/* Update your watch UI to conform to the ambient mode */
}

static void
watch_app_lang_changed(app_event_info_h event_info, void *user_data)
{
	/*APP_EVENT_LANGUAGE_CHANGED*/
	char *locale = NULL;
	app_event_get_language(event_info, &locale);
	elm_language_set(locale);
	free(locale);
	return;
}

static void
watch_app_region_changed(app_event_info_h event_info, void *user_data)
{
	/*APP_EVENT_REGION_FORMAT_CHANGED*/
}

int
main(int argc, char *argv[])
{
	appdata_s ad = {0,};
	int ret = 0;

	watch_app_lifecycle_callback_s event_callback = {0,};
	app_event_handler_h handlers[5] = {NULL, };

	event_callback.create = app_create;
	event_callback.terminate = app_terminate;
	event_callback.pause = app_pause;
	event_callback.resume = app_resume;
	event_callback.app_control = app_control;
	event_callback.time_tick = app_time_tick;
	event_callback.ambient_tick = app_ambient_tick;
	event_callback.ambient_changed = app_ambient_changed;

	watch_app_add_event_handler(&handlers[APP_EVENT_LANGUAGE_CHANGED],
		APP_EVENT_LANGUAGE_CHANGED, watch_app_lang_changed, &ad);
	watch_app_add_event_handler(&handlers[APP_EVENT_REGION_FORMAT_CHANGED],
		APP_EVENT_REGION_FORMAT_CHANGED, watch_app_region_changed, &ad);

	ret = watch_app_main(argc, argv, &event_callback, &ad);
	if (ret != APP_ERROR_NONE) {
		dlog_print(DLOG_ERROR, LOG_TAG, "watch_app_main() is failed. err = %d", ret);
	}

	return ret;
}

