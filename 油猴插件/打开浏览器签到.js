// ==UserScript==
// @name         自动签到脚本
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  打开浏览器时自动签到
// @author       YourName
// @match        *.bing.com/*
// @grant        GM_notification
// @grant        GM_getValue
// @grant        GM_setValue
// @grant        GM_xmlhttpRequest
// @run-at       document-start
// ==/UserScript==

(function () {
  'use strict';

  // 签到主函数
  const doSign = function (formhash) {
    // 构造请求参数
    const params = new URLSearchParams();
    params.append('id', 'dsu_paulsign:sign');
    params.append('operation', 'qiandao');
    params.append('formhash', formhash);
    params.append('qdxq', 'ch'); // 心情参数
    params.append('qdmode', '2'); // 签到模式
    params.append('todaysay', '');
    params.append('fastreply', '1');
    console.log("获取到的formhash为：" + formhash);
    // 发送签到请求
    GM_xmlhttpRequest({
      method: "POST",
      url: "https://www.tangguo2.com/plugin.php?infloat=1&inajax=1",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Origin": "https://www.tangguo2.com",
        "Referer": "https://www.tangguo2.com/plugin.php?id=dsu_paulsign:sign"
      },
      data: params.toString(),
      responseType: "arraybuffer", // 获取原始字节数据
      onload: function (response) {
        if (response.status === 200) {
          const uint8Array = new Uint8Array(response.response);
          const decoder = new TextDecoder('gbk'); // 假设服务器返回的是 GBK 编码
          const decodedText = decoder.decode(uint8Array);
          handleResponse(decodedText);
        } else {
          showNotification('签到失败，状态码：' + response.status);
        }
      },
      onerror: function (error) {
        showNotification('请求失败：' + error);
        alert("脚本已成功运行！结果为：请求失败：" + error)
      }
    });
  }

  const doApplyTask = function () {
    GM_xmlhttpRequest({
      method: "GET",
      url: "https://www.tangguo2.com/home.php?mod=task&do=apply&id=13",
      headers: {
        "Origin": "https://www.tangguo2.com",
        "Referer": "https://www.tangguo2.com/home.php?mod=task&do=apply&id=13"
      },
      responseType: "arraybuffer", // 获取原始字节数据
      onload: function (response) {
        if (response.status === 200) {
          const uint8Array = new Uint8Array(response.response);
          const decoder = new TextDecoder('gbk'); // 假设服务器返回的是 GBK 编码
          const decodedText = decoder.decode(uint8Array);
          const resultMatch = decodedText.match("抱歉，本期您已申请过此任务，请下期再来");
          const resultMatchError = decodedText.match("抱歉，本期您已申请过此任务，请下期再来");
          console.log(decodedText);
          console.log("resultMatch=" + resultMatch)
          console.log("resultMatchError=" + resultMatchError)
          if (resultMatch !== null || resultMatchError !== null) {
            const today = new Date().toDateString();
            GM_setValue('lastApply', today);
            console.log("任务申请成功")
            return;
          }
          console.log("任务申请失败")
        } else {
          console.log("任务申请失败" + response.status);
        }
      },
      onerror: function (error) {
        alert("任务失败失败：" + error)
      }
    });
  }

  // 获取动态formhash
  const getFormhash = () => {
    return new Promise(resolve => {
      GM_xmlhttpRequest({
        method: "GET",
        url: "https://www.tangguo2.com/plugin.php?id=dsu_paulsign:sign",
        responseType: "arraybuffer", // 获取原始字节数据
        onload: function (response) {
          const uint8Array = new Uint8Array(response.response);
          const decoder = new TextDecoder('gbk'); // 假设服务器返回的是 GBK 编码
          const decodedText = decoder.decode(uint8Array);

          const formhashMatch = decodedText.match(/formhash=([a-f0-9]+)/);
          console.log("decodedText=" + decodedText)
          resolve(formhashMatch ? formhashMatch[1] : null);
        }
      });
    }).then((result) => {
      console.log("______decodedText_result______：", result)
      GM_setValue('formhash', result)
    });
  };

  // 处理签到响应
  const handleResponse = (text) => {
    const resultMatch = text.match(/<div class="c">\s*([^<]+)\s*<\/div>/);
    // console.log(text);
    console.log("脚本已成功运行！结果为：" + resultMatch[1].trim());
    // alert("脚本已成功运行！结果为：" + resultMatch[1].trim())
    if (resultMatch) {
      showNotification(resultMatch[1].trim());
      const today = new Date().toDateString();
      GM_setValue('lastSignWindow', today);
    } else if (text.includes('今日已签')) {
      showNotification('今日已完成签到');
      const today = new Date().toDateString();
      GM_setValue('lastSignWindow', today);
    } else {
      showNotification('签到结果解析失败');
      GM_setValue('lastSignWindow', null);
    }
  };

  // 显示桌面通知
  const showNotification = (msg) => {
    GM_notification({
      title: '糖果社区签到',
      text: msg,
      timeout: 5000
    });
  };


  const getImageCode = function (base64String) {
    // 调用自动识别验证码接口
    // https://imgcode.toolshu.com/api
    console.log('请求的 base64String:', base64String);
    GM_xmlhttpRequest({
      method: "POST",
      url: "https://imgcode.toolshu.com/api",
      headers: {
        "Content-Type": "application/json",
        "Origin": "https://imgcode.toolshu.com",
        "Referer": "https://imgcode.toolshu.com/api"
      },
      data: JSON.stringify({ // 将请求体转换为 JSON 字符串
        "token": "ts_COW8RP63VYBH0PJU41ZGESC3D", // API Token
        "file": base64String // 去掉 Base64 数据的前缀
      }),
      responseType: "json", // 设置响应类型为 JSON
      onload: function (response) {
        console.log('响应数据:', response.response);
        if (response.status !== 200) {
          console.error("请求失败，状态码:", response.status);
          return;
        }

        // 解析响应数据
        const responseData = response.response; // 响应数据是 JSON 对象
        const dataValue = responseData.data;
        // console.log('提取的 data 值:', dataValue);
        GM_setValue('dataValue', dataValue);
      },
      onerror: function (error) {
        console.error('错误:', error);
      }
    });
  }


  const getImage = function (formhash) {
    console.log('请求的 formhash:', formhash);
    GM_xmlhttpRequest({
      method: "GET",
      url: "https://www.tangguo2.com/misc.php?mod=seccode&update=66863&idhash=" + formhash,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Origin": "https://www.tangguo2.com",
        "Referer": "https://www.tangguo2.com/misc.php"
      },
      responseType: "arraybuffer",
      onload: function (response) {
        // console.log('响应状态码:', response.status);
        // console.log('响应头部:', response.responseHeaders);

        if (response.status !== 200) {
          console.error("请求失败，状态码:", response.status);
          return;
        }
        console.log('响应数据:', response.response);
        const blob = new Blob([response.response], {type: 'image/png'});

        // 将 Blob 转换为 Base64 字符串
        const base64StringPromise = new Promise((resolve, reject) => {
          const reader = new FileReader();
          reader.onloadend = () => resolve(reader.result); // 获取完整的 Base64 数据 URL
          reader.onerror = reject;
          reader.readAsDataURL(blob);
        });

        console.log("base64StringPromise:", base64StringPromise);
        // setTimeout(() => {}, 5000);
        base64StringPromise.then((result) => {
          console.log("______result______：", result)
          if (result === "data:image/png;base64,QWNjZXNzIERlbmllZA==") {
            alert("脚本已成功运行！结果为：获取验证码失败")
            return;
          }
          GM_setValue('base64String', result);
        });
      },
      onerror: function (error) {
        console.error('错误:', error);
      }
    });
  };

  const doComment = function (dataValue, formhash) {
    // 构造请求参数
    console.log('请求的 dataValue:', dataValue);
    console.log('请求的 formhash:', formhash);
    const params = new URLSearchParams();
    params.append('message', '不清楚，桌子上的VR资源分享网站就是给力！');
    params.append('seccodehash', 'cSmX0Gzc');
    params.append('seccodemodid', 'forum::viewthread');
    params.append('seccodeverify', dataValue);
    params.append('formhash', formhash);
    params.append('subject', '');
    params.append('usesig', '');

    // 发送签到请求
    GM_xmlhttpRequest({
      method: "POST",
      url: "https://www.tangguo2.com/forum.php?mod=post&action=reply&fid=61&tid=2376&extra=page%3D1&replysubmit=yes&infloat=yes&handlekey=fastpost&inajax=1",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Origin": "https://www.tangguo2.com/forum.php",
        "Referer": "https://www.tangguo2.com/forum.php"
      },
      data: params.toString(),
      responseType: "arraybuffer", // 获取原始字节数据
      onload: function (response) {
        if (response.status === 200) {
          const uint8Array = new Uint8Array(response.response);
          const decoder = new TextDecoder('gbk'); // 假设服务器返回的是 GBK 编码
          const decodedText = decoder.decode(uint8Array);
          const resultMatch = decodedText.match("非常感谢，回复发布成功");
          console.log(decodedText);
          console.log(resultMatch)
          if (resultMatch !== null) {
            const today = new Date().toDateString();
            GM_setValue('lastComment', today);
            console.log("发布成功")
            return;
          }
          console.log("发布失败")
        } else {
          console.log("发布失败" + response.status);
        }
      },
      onerror: function (error) {
        showNotification('请求失败：' + error);
        alert("脚本已成功运行！结果为：请求失败：" + error)
      }
    });
  }

  const getDraw = function () {
    // 发送签到请求
    GM_xmlhttpRequest({
      method: "POST",
      url: "https://www.tangguo2.com/home.php?mod=task&do=draw&id=13",
      headers: {
        "Origin": "https://www.tangguo2.com/forum.php",
        "Referer": "https://www.tangguo2.com/forum.php"
      },
      responseType: "arraybuffer", // 获取原始字节数据
      onload: function (response) {
        if (response.status === 200) {
          const uint8Array = new Uint8Array(response.response);
          const decoder = new TextDecoder('gbk'); // 假设服务器返回的是 GBK 编码
          const decodedText = decoder.decode(uint8Array);

          const resultMatch = decodedText.match("恭喜您，任务已成功完成，您将收到奖励通知，请注意查收");
          const resultMatchError = decodedText.match("不是进行中的任务");
          console.log(decodedText);
          console.log(resultMatch)
          console.log(resultMatchError)
          if (resultMatch !== null) {
            const today = new Date().toDateString();
            GM_setValue('lastDraw', today);
            console.log("领取成功")
            return;
          }
        } else {
          console.log("领取失败" + response.status);
        }
      },
      onerror: function (error) {
        showNotification('请求失败：' + error);
        alert("脚本已成功运行！结果为：请求失败：" + error)
      }
    });
  }

  // 在页面加载完成后执行签到
  window.addEventListener('load', () => {
    // 正在执行
    if (GM_getValue('isRunning', false)) {
      console.log('正在执行签到，请稍后...');
      return;
    }
    GM_setValue('isRunning', true)
    setTimeout(() => {GM_setValue('isRunning', false)}, 12000)
    try {
      const today = new Date().toDateString();
      console.log('页面加载完成，开始自动签到...');
      const lastSignWindow1 = GM_getValue('lastSignWindow', '');
      const lastApply1 = GM_getValue('lastApply', '');
      const lastComment1 = GM_getValue('lastComment', '');
      const lastDraw1 = GM_getValue('lastDraw', '');

      if (lastSignWindow1 === today && lastApply1 === today && lastComment1 === today && lastDraw1 === today) {
        console.log('已全部执行成功')
        return
      }
      getFormhash();
      setTimeout(() => {
        // 先获取formhash（动态获取更安全）
        const formhash = GM_getValue('formhash', '')
        if (!formhash) {
          alert("脚本已成功运行！结果为：获取formhash失败")
          showNotification('获取formhash失败');
          console.log(formhash)
          return;
        }
        const lastSignWindow = GM_getValue('lastSignWindow', '');
        if (lastSignWindow !== today) {
          doSign(formhash)
        }

        // 申请任务
        const lastApply = GM_getValue('lastApply', '');
        if (lastApply !== today) {
          doApplyTask()
        }
        // 评论
        console.log('页面加载完成，开始自动评论...');
        const lastComment = GM_getValue('lastComment', '');
        if (lastComment !== today) {
          getImage(formhash);
          setTimeout(() => {
            const base64String = GM_getValue('base64String', '');
            GM_setValue('dataValue', '');
            if (base64String !== "") {
              getImageCode(base64String)
            }
            setTimeout(() => {
              let dataValue = GM_getValue('dataValue', '');
              if (dataValue === "") {
                setTimeout(() => {
                  dataValue = GM_getValue('dataValue', '')
                  if (dataValue !== "") {
                    doComment(dataValue, formhash)
                    // 获取奖励
                    setTimeout(() => {
                      getDraw();
                    }, 2000)
                  }
                }, 2000)
              } else {
                doComment(dataValue, formhash)
                setTimeout(() => {
                  getDraw();
                }, 2000)
              }
            }, 2000)
          }, 2000);
        }

        setTimeout(() => {
          const lastSignWindow2 = GM_getValue('lastSignWindow', '');
          const lastApply2 = GM_getValue('lastApply', '');
          const lastComment2 = GM_getValue('lastComment', '');
          const lastDraw2 = GM_getValue('lastDraw', today);
          alert("脚本已成功运行！结果为：" +
              "lastSignWindow=" + (lastSignWindow2 === today) + " " +
              "lastApply=" + (lastApply2 === today) + " " +
              "lastComment=" + (lastComment2 === today) + " " +
              "lastDraw=" + (lastDraw2 === today))
        }, 12000)
      }, 3000)
    } catch (error) {
      console.error('发生错误：', error);
      alert("脚本已成功运行！结果为：发生错误：" + error)
    }
  });
})();