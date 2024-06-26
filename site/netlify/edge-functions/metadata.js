function decodePrettyComponent(s) {
  let replacements = {'---': ' - ', '--': '-','-' : ' '}
  return decodeURIComponent(s.replace(/-+/g, e => replacements[e] ?? '-'))
}

function decodeURL(s) {
  if (s.startsWith("http")) return s;
  if (s.startsWith(".")) return s;
  if (s.startsWith("/")) return s;
  try {
    return atob(s.replace(/=/g,''))
  } catch (e) {
    return s;
  }
}

function atou(b64) { return decodeURIComponent(escape(atob(b64))); }
function utoa(data) { return btoa(unescape(encodeURIComponent(data))); }

let urlValues = ["u","i","v","f"];
function pathToMetadata(path) {
  let components = path.substring(1).split("/");
  components.unshift("t"); // Title designation for the first element
  let info = {}
  for (let i = 0; i < components.length; i+=2) {
    let key = components[i];
    let value = components[i+1];
    if (!value) continue;
    if (urlValues.includes(key)) {
      value = decodeURIComponent(value);
      if (value.startsWith(":")) value = "https://" + value.substring(1);
    } else {
      value = decodePrettyComponent(value);
    }
    if (key.length && value.length) info[key] = value;
  }
  return info;
}

function mProp(prop, content) { return `<meta property="${prop}" content="${content}"/>` }
function mName(name, content) { return `<meta name="${name}" content="${content}"/>` }

// Valid URL Chars A-Za-z0-9-._~:?@!$&()*;=+/
export default async (request, context) => {
  console.log("Request", request.url)
  try {
    const ua = request.headers.get("user-agent");
    let url = new URL(request.url);
    let path = url.pathname.substring(1);
    if (path.startsWith("list") 
        || path.startsWith("assets") 
        || path.startsWith("widgets") 
        || path.startsWith("favicon.ico") 
        || path.startsWith(".well-known") 
        || path.length == 0) {
      return;
    }
    
    console.log("Path", path)
    // let geo = context?.geo?.city + ", " + context?.geo?.subdivision?.code + ", " + context?.geo?.country?.code
    
    let uaArray = Deno.env.get("UA_ARRAY")?.split(",") || [];
    let uaMatch = uaArray.some(a => ua?.indexOf(a) != -1);
    if (uaMatch) { return new Response('', { status: 401 }); }
    
    let info = {}
    // if (request.url.indexOf('?v=') > 0) {
    // let wvQuery = request.url.substring(request.url.indexOf('?v='));
    let params = new URLSearchParams(url.search);
    info = Object.fromEntries(params.entries());
    console.log("Info", info);
    // }
    
    path = decodeURIComponent(path)
    if (!path.startsWith("http")) {
      path = "https://" + path;
    }
    
    let targetURL = new URL(path);
    let title = info.name || info.title || targetURL.hostname || "Untitled Widget";
    let description = info.description || targetURL.hostname;
    
    var content = ['<meta charset="UTF-8">'];
    if (title) { content.push(`<title>${title}</title>`,mProp("og:title", title)) }
    if (info.s) { content.push(mProp("og:site_name", url.hostname)) }
    if (description) { content.push(mProp("og:description", description), mName("description", description)) }
    
    content.push(mProp("og:image", info.image || "https://translucent.vision/assets/img/translucent.vision.png")); 
    
    let widgetURL = null;
    if (targetURL) {
      widgetURL = `widget-${targetURL}${url.search}${url.hash}`
      content.push(mProp("og:url", targetURL));
    }
    // content.push(mName("twitter:card", "summary_large_image"));    
    //  content.push(`<link rel="icon" type="image/png" href="${decodeURL(new URL(info.f, info.u).href)}">`);
    content.push(`
    <style>
    body { font-family: sans-serif; font-size: 1.2em; color: #fff;
      background-color:#16161d;
      display: flex; justify-content: center; align-items: center; height: 66vh;
    }
    .widget {
      padding: 40px 40px 40px 40px;  border-radius: 30px;
      border:2px solid #fff1;
      min-width:320px;
      line-height: 1.5em;
      color: #ccc;
      text-align: center;
     }
    a { color: #fff; text-decoration: none;}
    a:hover { color: #fff; text-decoration: underline;}
    </style>
    
<body>
    <div class="widget">
    Opening <a href="${widgetURL}">${title}</a><br>in <a href="https://translucent.vision">translucent.vision</a>
    </div>
</body>`);

    if (widgetURL) {
      content.push(`<script>setTimeout(() => {location.href="${widgetURL}"; }, 1)</script>`);
    }

    return new Response(content.join("\n"), {
      headers: { "content-type": "text/html" },
    });
  } catch (e) {
    console.log("Error:", request.url, e)
  }
}
