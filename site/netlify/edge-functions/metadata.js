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

  try {
    const ua = request.headers.get("user-agent");
    let url = new URL(request.url);
    let path = url.pathname;
    let geo = context?.geo?.city + ", " + context?.geo?.subdivision?.code + ", " + context?.geo?.country?.code

    let uaArray = Deno.env.get("UA_ARRAY")?.split(",") || [];
    let uaMatch = uaArray.some(a => ua?.indexOf(a) != -1);
    if (uaMatch) { return new Response('', { status: 401 }); }
    
    if (path != "/" ) {
      
      let metadataBots = [ "Twitterbot", "curl", "facebookexternalhit", "Slackbot-LinkExpanding", "Discordbot", "snapchat", "Googlebot"]
      let isMetadataBot = metadataBots.some(bot => ua?.indexOf(bot) != -1);

      if (path.startsWith("/m/")) {
        path = path.substring(2);
        isMetadataBot = true;
      }
      
      if (isMetadataBot && path.endsWith("/")) {
        console.log("parsing", path)
        let info = pathToMetadata(path)

        let content = ['<meta charset="UTF-8">'];
        if (info.t) { content.push(`<title>${info.t}</title>`,mProp("og:title", info.t)) }
        if (info.s) { content.push(mProp("og:site_name", info.s)) }
        if (info.y) { content.push(mProp("og:type", info.y)) }
        if (info.d) { content.push(mProp("og:description", info.d),mName("description",info.d)) }
        if (info.c) { content.push(mName("theme-color","#" + info.c)) }

        if (info.u) {
          info.u = decodeURL(info.u)
          if (!info.u.startsWith("http")) info.u = "https://" + info.u;
          content.push(mProp("og:url", info.u));
          content.push(`<script>location.href="${info.u}"</script>`);
        } else {
          // content.push(`<script>l=location;l.href=l.hash.substring(1)||'//www.'+l.host</script>`);
        }
        
        if (info.i) {
          info.i = decodeURL(info.i)
          if (info.i.startsWith("svg:")) {
            info.i = "/.netlify/functions/rasterize/" + info.i;
          } else if (info.u && (info.i.startsWith(".") || info.i.startsWith("/"))) {
            info.i = new URL(info.i, info.u).href
          } else {
            info.i = "https://" + info.i;
          }

          content.push(mProp("og:image", info.i)); 
          if (info.iw) content.push(mProp("og:image:width", info.iw)); 
          if (info.ih) content.push(mProp("og:image:width", info.ih)); 
          content.push(mName("twitter:card", "summary_large_image"));
        } 
        if (info.v) {
          content.push(mProp("og:video", decodeURL(info.v))); 
          if (info.vw) content.push(mProp("og:image:width", info.vw)); 
          if (info.vh) content.push(mProp("og:image:width", info.vh)); 
        } 
        if (info.f) { // Favicon: URL Encoded
          if (info.f.length > 9){      
            content.push(`<link rel="icon" type="image/png" href="${decodeURL(new URL(info.f, info.u).href)}">`);
          } else {
            let codepoints = Array.from(info.f).map(c => c.codePointAt(0).toString(16));
            content.push(`<link rel="icon" type="image/png" href="https://fonts.gstatic.com/s/e/notoemoji/14.0/${codepoints.join("_")}/128.png">`);
          }
        }


      
        console.log(["Metadata Request", JSON.stringify(info), geo, ua].join('\t')); 
        return new Response(content.join("\n"), {
          headers: { "content-type": "text/html" },
        });
      } 
    } else {
      console.log(["Request", path, geo, request.headers.get("referer"), ua].join('\t'));
    }
  } catch (e) {
    console.log("Error:", request.url, e)
  }
}
