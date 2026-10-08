#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
OpenHW Lab · 下载机+NAS 管理面板 (nasd.py)
- 下载面板：aria2 全局速度 / 活动·等待任务 / 加任务(磁力·URL·BT)
- 二维码：手机扫码用 / AriaNg / 网盘(SMB) —— 服务器端生成并内嵌(data URI)，不依赖 JS
- 端口 8080；AriaNg 静态托管在 /ariang/
"""
import os, json, time, socket, base64, subprocess, urllib.request, mimetypes
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

PORT     = int(os.environ.get("NASD_PORT", "8080"))
RPC      = os.environ.get("ARIA2_RPC", "http://127.0.0.1:6800/jsonrpc")
rpcAuth  = os.environ.get("ARIA2_SECRET", "openhwlab")
NAS_ROOT = os.environ.get("NAS_ROOT", "/media/usb/nas")
DL_DIR   = os.environ.get("NAS_DL", os.path.join(NAS_ROOT, "downloads"))
ARIANG   = os.environ.get("ARIANG_DIR", "/root/ariang")

def box_ip():
    ip = os.environ.get("BOX_IP")
    if ip: return ip
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80)); ip = s.getsockname()[0]; s.close()
    except Exception:
        ip = "127.0.0.1"
    return ip

def qr_data_uri(text):
    try:
        png = subprocess.run(["qrencode", "-o", "-", "-t", "PNG", "-s", "4", "-m", "1", text],
                             capture_output=True, timeout=8).stdout
        if png:
            return "data:image/png;base64," + base64.b64encode(png).decode()
    except Exception:
        pass
    return ""

def rpc(method, params=None):
    payload = {"jsonrpc": "2.0", "id": str(int(time.time() * 1000)),
               "method": method, "params": ["token:" + rpcAuth] + (params or [])}
    req = urllib.request.Request(RPC, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=6) as r:
        return json.loads(r.read().decode())

def target_label():
    try:
        t = open("/root/nas-active").read().strip()
    except Exception:
        t = "internal"
    if t.startswith("USB:"):
        return "存储：外接盘/U盘 " + t[4:]
    return "存储：内部存储"

def disk():
    try:
        st = os.statvfs(NAS_ROOT)
        t = st.f_blocks * st.f_frsize; f = st.f_bavail * st.f_frsize
        return {"total": t, "free": f, "used": t - f, "pct": (t - f) / t * 100 if t else 0, "target": target_label()}
    except Exception as e:
        return {"error": str(e), "target": target_label()}

STATUS = {"active": "下载中", "waiting": "排队等待", "paused": "已暂停",
          "complete": "已完成", "error": "出错", "removed": "已删除"}

def _tasks(res):
    out = []
    for t in res.get("result", []):
        tot = int(t.get("totalLength") or 0); done = int(t.get("completedLength") or 0)
        path = (t.get("files") or [{}])[0].get("path", "") if t.get("files") else ""
        out.append({"gid": t.get("gid"), "name": os.path.basename(path) or t.get("gid"),
                    "pct": round(done / tot * 100, 1) if tot else 0,
                    "spd": int(t.get("downloadSpeed") or 0),
                    "status": STATUS.get(t.get("status"), t.get("status"))})
    return out

KEYS = ["gid", "totalLength", "completedLength", "downloadSpeed", "files", "status"]

def state():
    try:
        g = rpc("aria2.getGlobalStat")["result"]
        return {"ok": True, "disk": disk(),
                "global": {"down": int(g.get("downloadSpeed", 0)), "up": int(g.get("uploadSpeed", 0)),
                           "active": g.get("numActive"), "waiting": g.get("numWaiting")},
                "active": _tasks(rpc("aria2.tellActive", [KEYS])),
                "waiting": _tasks(rpc("aria2.tellWaiting", [0, 30, KEYS])),
                "stopped": _tasks(rpc("aria2.tellStopped", [0, 10, KEYS]))}
    except Exception as e:
        return {"ok": False, "err": str(e), "disk": disk(), "active": [], "waiting": [], "stopped": []}

PAGE = r"""<!doctype html><html lang=zh><head><meta charset=utf-8>
<meta name=viewport content="width=device-width,initial-scale=1">
<title>OpenHW Lab - 下载机 + NAS</title><style>
body{margin:0;background:#0b1220;color:#dbe6f5;font-family:-apple-system,"Noto Sans CJK SC",sans-serif}
.wrap{max-width:900px;margin:0 auto;padding:16px}
h1{font-size:20px;margin:6px 0 12px}.hl{color:#7fd0ff}
.card{background:#131d30;border:1px solid #22314b;border-radius:14px;padding:14px;margin:10px 0}
.row{display:flex;gap:10px;flex-wrap:wrap}.row>*{flex:1;min-width:150px}
.k{color:#8ea3c0;font-size:13px}.v{font-size:22px;font-weight:800}
.bar{height:8px;background:#22314b;border-radius:4px;overflow:hidden;margin:6px 0}
.bar>i{display:block;height:100%;background:linear-gradient(90deg,#4a9df0,#7fd0ff)}
input,button{font:inherit}.in{flex:3;padding:10px;border-radius:10px;border:1px solid #22314b;background:#0a1322;color:#dbe6f5}
.add{flex:1;background:#2f6fd0;color:#fff;border:0;border-radius:10px;padding:10px;cursor:pointer}
.t{display:flex;justify-content:space-between;gap:8px;font-size:14px;padding:6px 0;border-bottom:1px solid #1c2a42}
.b{border:0;border-radius:8px;padding:5px 12px;font-size:13px;cursor:pointer;margin-left:6px;background:#24344f;color:#cfe0f5}
.b.del{background:#5a2530;color:#ffd7d7}.b.on{background:#2f6fd0;color:#fff}
.s{color:#8ea3c0;font-size:12px}.q{text-align:center}.q img{background:#fff;border-radius:8px;padding:6px}
.bigbtn{font-size:22px;font-weight:800;padding:16px 30px;background:linear-gradient(180deg,#3a90ea,#2f6fd0);color:#fff;border-radius:14px;text-decoration:none;box-shadow:0 6px 18px rgba(47,111,208,.35);white-space:nowrap}
a{color:#4a9df0}</style></head><body><div class=wrap>
<h1><span class=hl>OpenHW Lab</span> &middot; 下载机 + NAS</h1>
<div class=card style="display:flex;align-items:center;gap:16px;flex-wrap:wrap">
  <img src="__QR0__" width=56 alt=QR style="flex:0 0 auto;background:#fff;border-radius:8px;padding:4px">
  <div class=s style="flex:1 1 100%">手机扫码或输入 __MAIN__ 即可加任务</div></div>
<div class=card><div class=k>下载速度</div><div class=v id=spd>-</div>
  <div class=k id=act style="margin-top:6px">活动 - &middot; 等待 -</div></div>
<div class=card><div class=k>网盘空间</div>
  <div class=bar><i id=dbar style="width:0%"></i></div><div class=k id=dinfo>-</div><div class=s id=stor>-</div></div>
<div class=card><div class=k>添加任务（磁力 / 种子URL / 直链）</div>
  <div class=row style="margin-top:8px"><input id=u class=in placeholder="magnet:?xt=... 或 http(s)://...">
  <button class=add onclick="add()">下载</button></div><div id=msg class=s style="margin-top:6px"></div></div>
<div class=card><div class=k>活动 / 等待</div><div id=tasks class=s>加载中...</div></div>
<div class=s>网盘：__SMB__ &middot; 面板每 3 秒刷新</div>
<script>
var lastOk=0;
var $=function(id){return document.getElementById(id);};
var fmt=function(n){var u=["B","K","M","G","T"],i=0;n=Number(n);while(n>=1024&&i<4){n=n/1024;i++;}return n.toFixed(1)+u[i];};
var setT=function(id,t){var e=$(id);if(e)e.textContent=t;};
var esc=function(s){return String(s).replace(/[&<>]/g,function(c){return c=="&"?"&amp;":c=="<"?"&lt;":"&gt;";});};
var xhr=function(method,url,body,cb){var x=new XMLHttpRequest();x.open(method,url,true);x.setRequestHeader("Content-Type","application/json");
 x.onreadystatechange=function(){if(x.readyState==4){cb(x.responseText);}};x.send(body||null);};
function load(){xhr("GET","/api/state",null,function(txt){var d;try{d=JSON.parse(txt);}catch(e){return;}lastOk=new Date().getTime();
 var g=d.global||{};
 setT("spd",fmt(g.down||0)+"/s \u2191"+fmt(g.up||0)+"/s");
 setT("act","活动 "+(d.ok?g.active:"-")+" \u00b7 等待 "+(d.ok?g.waiting:"-")+(d.ok?"":"  \u26a0"+(d.err||"")));
 var dk=d.disk||{};var b=$("dbar");if(b)b.style.width=(dk.error?0:(100-dk.pct)).toFixed(0)+"%";
 setT("dinfo",dk.error?dk.error:(fmt(dk.used)+" / "+fmt(dk.total)+"（剩 "+fmt(dk.free)+"）"));
 setT("stor",dk.target||"");
 var tt=[],i,x;
 if(d.active)for(i=0;i<d.active.length;i++)tt.push(["\u2b07",d.active[i]]);
 if(d.waiting)for(i=0;i<d.waiting.length;i++)tt.push(["\u23f8",d.waiting[i]]);
 if(d.stopped)for(i=0;i<d.stopped.length&&i<6;i++)tt.push(["\u2714",d.stopped[i]]);
 var h="";if(!tt.length)h="暂无任务";
 for(i=0;i<tt.length;i++){x=tt[i][1];var right=(x.spd>0)?(x.pct+'% \u00b7 '+fmt(x.spd)+'/s'):(x.pct+'% \u00b7 '+x.status);
  var btn="";
  if(x.status=="\u4e0b\u8f7d\u4e2d")btn+='<button class=b onclick="pa(\''+x.gid+'\')">\u6682\u505c</button>';
  else if(x.status=="\u6392\u961f\u7b49\u5f85"||x.status=="\u5df2\u6682\u505c")btn+='<button class="b on" onclick="rs(\''+x.gid+'\')">\u7ee7\u7eed</button>';
  btn+='<button class="b del" onclick="rm(\''+x.gid+'\')">\u5220\u9664</button>';
  h+='<div class=t><span>'+tt[i][0]+' '+esc((x.name||"").substr(0,60))+'</span><span class=s>'+right+btn+'</span></div>';}
 $("tasks").innerHTML=h;});}
function add(){var u=$("u").value;if(!u||!u.replace(/\s/g,""))return;xhr("POST","/api/add",JSON.stringify({url:u}),function(r){$("u").value="";var m=$("msg");if(m)m.textContent="\u2714 已添加，下载中…";load();});}
function act(p,g){xhr("POST",p,JSON.stringify({gid:g}),function(){load();});}
function pa(g){act("/api/pause",g);}
function rs(g){act("/api/resume",g);}
function rm(g){act("/api/remove",g);}
load();setInterval(load,10000);setInterval(function(){if(lastOk&&(new Date().getTime()-lastOk>60000)){location.reload();}},5000);
</script></div></body></html>"""

def page():
    ip = box_ip()
    main = "http://%s:8080/" % ip
    aria = main + "ariang/"
    smb = "\\\\%s\\nas" % ip
    return (PAGE.replace("__QR0__", qr_data_uri(main))
                .replace("__QR1__", qr_data_uri(aria))
                .replace("__QR2__", qr_data_uri("smb://%s/nas" % ip))
                .replace("__MAIN__", main)
                .replace("__ARIA__", aria)
                .replace("__SMB__", smb))

class H(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype="text/html; charset=utf-8"):
        if isinstance(body, str): body = body.encode("utf-8")
        self.send_response(code); self.send_header("Content-Type", ctype)
        self.send_header("Cache-Control", "no-store"); self.end_headers()
        self.wfile.write(body)

    def log_message(self, *a): pass

    def do_GET(self):
        u = urlparse(self.path); p = u.path
        if p in ("/", "/index.html"):
            return self._send(200, page())
        if p == "/api/state":
            return self._send(200, json.dumps(state()), "application/json")
        if p == "/qr.png":  # 兼容旧引用
            q = parse_qs(u.query).get("u", [""])[0]
            try:
                png = subprocess.run(["qrencode", "-o", "-", "-t", "PNG", "-s", "6", "-m", "1", q],
                                     capture_output=True, timeout=8).stdout
            except Exception:
                png = b""
            return self._send(200, png, "image/png") if png else self._send(404, "err")
        if p.startswith("/ariang"):
            rel = p[len("/ariang"):].lstrip("/") or "index.html"
            fp = os.path.normpath(os.path.join(ARIANG, rel))
            if fp.startswith(ARIANG) and os.path.isfile(fp):
                ct = mimetypes.guess_type(fp)[0] or "application/octet-stream"
                return self._send(200, open(fp, "rb").read(), ct)
            return self._send(404, "AriaNg 未安装（/root/ariang）")
        return self._send(404, "not found")

    def do_POST(self):
        n = int(self.headers.get("Content-Length") or 0)
        try: data = json.loads(self.rfile.read(n) or b"{}")
        except Exception: data = {}
        try:
            if self.path == "/api/add":
                r = rpc("aria2.addUri", [[data.get("url", "")], {"dir": DL_DIR}])
                return self._send(200, json.dumps({"gid": r.get("result")}), "application/json")
            if self.path == "/api/pause":
                rpc("aria2.pause", [data["gid"]]); return self._send(200, "{}", "application/json")
            if self.path == "/api/resume":
                rpc("aria2.unpause", [data["gid"]]); return self._send(200, "{}", "application/json")
            if self.path == "/api/remove":
                g = data["gid"]
                try: rpc("aria2.remove", [g])
                except Exception: pass
                try: rpc("aria2.removeDownloadResult", [g])
                except Exception: pass
                return self._send(200, "{}", "application/json")
        except Exception as e:
            return self._send(500, json.dumps({"err": str(e)}), "application/json")
        return self._send(404, "{}")

if __name__ == "__main__":
    os.makedirs(DL_DIR, exist_ok=True)
    print("nasd on :%d  box_ip=%s  root=%s" % (PORT, box_ip(), NAS_ROOT))
    ThreadingHTTPServer(("0.0.0.0", PORT), H).serve_forever()
