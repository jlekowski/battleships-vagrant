vcl 4.0;

# Backend definition
backend default {
    .host = "127.0.0.1";
    .port = "8080";
}

sub vcl_recv {
    if (req.method == "PURGE") {
        if (!client.ip ~ invalidators) {
            return (synth(405, "Not allowed"));
        }
        return (purge);
    }

    if (req.method == "BAN") {
        if (!client.ip ~ invalidators) {
            return (synth(405, "Not allowed"));
        }

        if (req.http.X-Cache-Tags) {
            ban("obj.http.X-Host ~ " + req.http.X-Host
                + " && obj.http.X-Url ~ " + req.http.X-Url
                + " && obj.http.content-type ~ " + req.http.X-Content-Type
                + " && obj.http.X-Cache-Tags ~ " + req.http.X-Cache-Tags
            );
        } else {
            ban("obj.http.X-Host ~ " + req.http.X-Host
                + " && obj.http.X-Url ~ " + req.http.X-Url
                + " && obj.http.content-type ~ " + req.http.X-Content-Type
            );
        }

        return (synth(200, "Banned"));
    }

    # I don't use Cookies
    if (req.http.Cookie) {
        unset req.http.Cookie;
    }

    if (req.http.Cache-Control ~ "no-cache" && client.ip ~ invalidators) {
        set req.hash_always_miss = true;
    }

    # by default PATCH requests are not supported http://book.varnish-software.com/4.0/chapters/VCL_Basics.html#default-vcl-recv
    if (req.method == "PATCH") {
        return (pass);
    }

    # by default OPTIONS requests are not supported and I want return header for OPTIONS requests
    if (req.method == "OPTIONS") {
        #return (synth(204, "No Content")); # for web client to work faster - OPTIONS headers served from Varnish
        return (pass); # let API to respond to OPTIONS requests
    }

    if (req.http.Authorization && req.method == "GET") {
        # I want to cache requests with Authorization Header
        return (hash);
    }
}

sub vcl_synth {
    # It responds to all 204 synth (all OPTIONS request), not only the valid ones :/
    if (resp.status == 204) {
        set resp.http.Access-Control-Allow-Origin = "*";
        set resp.http.Access-Control-Allow-Methods = "GET, POST, PUT, PATCH, DELETE, OPTIONS";
        set resp.http.Access-Control-Allow-Headers = "Content-Type, Authorization, Accept, X-Requested-With";
        set resp.http.Access-Control-Expose-Headers = "Location, Api-Key";
    }

    return (deliver);
}

sub vcl_hash {
    hash_data(req.url);
    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }

    # Cache based on Authorization Header
    if (req.http.Authorization) {
        hash_data(req.http.Authorization);
    }

    return (lookup);
}

sub vcl_backend_response {
    # Set ban-lurker friendly custom headers
    set beresp.http.X-Url = bereq.url;
    set beresp.http.X-Host = bereq.http.host;
}

sub vcl_deliver {
    # Add extra headers if debugging is enabled
    # In Varnish 4 the obj.hits counter behaviour has changed, so we use a
    # different method: if X-Varnish contains only 1 id, we have a miss, if it
    # contains more (and therefore a space), we have a hit.
    if (resp.http.X-Cache-Debug) {
        if (resp.http.X-Varnish ~ " ") {
            set resp.http.X-Cache = "HIT";
        } else {
            set resp.http.X-Cache = "MISS";
        }
    # Keep ban-lurker headers only if debugging is enabled
    } else {
        # Remove ban-lurker friendly custom headers when delivering to client
        unset resp.http.X-Url;
        unset resp.http.X-Host;
        unset resp.http.X-Cache-Tags;
    }
}

acl invalidators {
    "127.0.0.1";
    # Add any other IP addresses that your application runs on and that you
    # want to allow invalidation requests from. For instance:
    #"192.168.1.0"/24;
}