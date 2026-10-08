package com.openhardwarelab.desktop;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.view.WindowManager;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

/**
 * 下载机+NAS「桌面」= 开机直进管理面板。
 * 全屏 WebView 载本机监控页 http://127.0.0.1:8080/（设置都在该页面里）。
 * 出错(服务未起)时每 3s 重试。
 */
public class MainActivity extends Activity {
    private static final String HOME = "http://127.0.0.1:8080/";
    private WebView web;
    private final Handler h = new Handler();

    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        web = new WebView(this);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setLoadWithOverviewMode(true);
        s.setUseWideViewPort(true);
        web.setWebViewClient(new WebViewClient() {
            @Override public void onReceivedError(WebView v, int ec, String desc, String url) {
                h.postDelayed(new Runnable() { public void run() { reload(); } }, 3000);
            }
        });
        setContentView(web);
        reload();
    }

    @Override protected void onResume() { super.onResume(); reload(); }

    private void reload() { if (web != null) web.loadUrl(HOME); }

    @Override public void onBackPressed() { /* 专用监控机：屏蔽返回键，始终停在监控画面 */ }
}
