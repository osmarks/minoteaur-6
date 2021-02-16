(()=>{var Kt=Object.create,Re=Object.defineProperty,Jt=Object.getPrototypeOf,Bt=Object.prototype.hasOwnProperty,Gt=Object.getOwnPropertyNames,Xt=Object.getOwnPropertyDescriptor;var Zt=n=>Re(n,"__esModule",{value:!0});var O=(n,i)=>()=>(i||(i={exports:{}},n(i.exports,i)),i.exports);var Wt=(n,i,u)=>{if(Zt(n),i&&typeof i=="object"||typeof i=="function")for(let c of Gt(i))!Bt.call(n,c)&&c!=="default"&&Re(n,c,{get:()=>i[c],enumerable:!(u=Xt(i,c))||u.enumerable});return n},Yt=n=>n&&n.__esModule?n:Wt(Re(n!=null?Kt(Jt(n)):{},"default",{value:n,enumerable:!0}),n);var Z=O((Lr,Ge)=>{"use strict";function te(n,i,u,c,b,h){return{tag:n,key:i,attrs:u,children:c,text:b,dom:h,domSize:void 0,state:void 0,events:void 0,instance:void 0}}te.normalize=function(n){return Array.isArray(n)?te("[",void 0,void 0,te.normalizeChildren(n),void 0,void 0):n==null||typeof n=="boolean"?null:typeof n=="object"?n:te("#",void 0,void 0,String(n),void 0,void 0)};te.normalizeChildren=function(n){var i=[];if(n.length){for(var u=n[0]!=null&&n[0].key!=null,c=1;c<n.length;c++)if((n[c]!=null&&n[c].key!=null)!==u)throw new TypeError("Vnodes must either always have keys or never have keys!");for(var c=0;c<n.length;c++)i[c]=te.normalize(n[c])}return i};Ge.exports=te});var Le=O((Dr,Xe)=>{"use strict";var kt=Z();Xe.exports=function(){var n=arguments[this],i=this+1,u;if(n==null?n={}:(typeof n!="object"||n.tag!=null||Array.isArray(n))&&(n={},i=this),arguments.length===i+1)u=arguments[i],Array.isArray(u)||(u=[u]);else for(u=[];i<arguments.length;)u.push(arguments[i++]);return kt("",n.key,n,u)}});var De=O((Ir,Ze)=>{"use strict";var We=Z(),vt=Le(),er=/(?:(^|#|\.)([^#\.\[\]]+))|(\[(.+?)(?:\s*=\s*("|'|)((?:\\["'\]]|.)*?)\5)?\])/g,Ye={},ne={}.hasOwnProperty;function ke(n){for(var i in n)if(ne.call(n,i))return!1;return!0}function tr(n){for(var i,u="div",c=[],b={};i=er.exec(n);){var h=i[1],o=i[2];if(h===""&&o!=="")u=o;else if(h==="#")b.id=o;else if(h===".")c.push(o);else if(i[3][0]==="["){var s=i[6];s&&(s=s.replace(/\\(["'])/g,"$1").replace(/\\\\/g,"\\")),i[4]==="class"?c.push(s):b[i[4]]=s===""?s:s||!0}}return c.length>0&&(b.className=c.join(" ")),Ye[n]={tag:u,attrs:b}}function rr(n,i){var u=i.attrs,c=We.normalizeChildren(i.children),b=ne.call(u,"class"),h=b?u.class:u.className;if(i.tag=n.tag,i.attrs=null,i.children=void 0,!ke(n.attrs)&&!ke(u)){var o={};for(var s in u)ne.call(u,s)&&(o[s]=u[s]);u=o}for(var s in n.attrs)ne.call(n.attrs,s)&&s!=="className"&&!ne.call(u,s)&&(u[s]=n.attrs[s]);(h!=null||n.attrs.className!=null)&&(u.className=h!=null?n.attrs.className!=null?String(n.attrs.className)+" "+String(h):h:n.attrs.className!=null?n.attrs.className:null),b&&(u.class=null);for(var s in u)if(ne.call(u,s)&&s!=="key"){i.attrs=u;break}return Array.isArray(c)&&c.length===1&&c[0]!=null&&c[0].tag==="#"?i.text=c[0].children:i.children=c,i}function nr(n){if(n==null||typeof n!="string"&&typeof n!="function"&&typeof n.view!="function")throw Error("The selector must be either a string or a component.");var i=vt.apply(1,arguments);return typeof n=="string"&&(i.children=We.normalizeChildren(i.children),n!=="[")?rr(Ye[n]||tr(n),i):(i.tag=n,i)}Ze.exports=nr});var et=O((_r,ve)=>{"use strict";var ir=Z();ve.exports=function(n){return n==null&&(n=""),ir("<",void 0,void 0,n,void 0,void 0)}});var rt=O((Sr,tt)=>{"use strict";var ar=Z(),fr=Le();tt.exports=function(){var n=fr.apply(0,arguments);return n.tag="[",n.children=ar.normalizeChildren(n.children),n}});var it=O((Mr,nt)=>{"use strict";var Ie=De();Ie.trust=et();Ie.fragment=rt();nt.exports=Ie});var _e=O((Hr,at)=>{"use strict";var S=function(n){if(!(this instanceof S))throw new Error("Promise must be called with `new`");if(typeof n!="function")throw new TypeError("executor must be a function");var i=this,u=[],c=[],b=l(u,!0),h=l(c,!1),o=i._instance={resolvers:u,rejectors:c},s=typeof setImmediate=="function"?setImmediate:setTimeout;function l(g,w){return function E(m){var C;try{if(w&&m!=null&&(typeof m=="object"||typeof m=="function")&&typeof(C=m.then)=="function"){if(m===i)throw new TypeError("Promise can't be resolved w/ itself");y(C.bind(m))}else s(function(){!w&&g.length===0&&console.error("Possible unhandled promise rejection:",m);for(var x=0;x<g.length;x++)g[x](m);u.length=0,c.length=0,o.state=w,o.retry=function(){E(m)}})}catch(x){h(x)}}}function y(g){var w=0;function E(C){return function(x){w++>0||C(x)}}var m=E(h);try{g(E(b),m)}catch(C){m(C)}}y(n)};S.prototype.then=function(n,i){var u=this,c=u._instance;function b(l,y,g,w){y.push(function(E){if(typeof l!="function")g(E);else try{h(l(E))}catch(m){o&&o(m)}}),typeof c.retry=="function"&&w===c.state&&c.retry()}var h,o,s=new S(function(l,y){h=l,o=y});return b(n,c.resolvers,h,!0),b(i,c.rejectors,o,!1),s};S.prototype.catch=function(n){return this.then(null,n)};S.prototype.finally=function(n){return this.then(function(i){return S.resolve(n()).then(function(){return i})},function(i){return S.resolve(n()).then(function(){return S.reject(i)})})};S.resolve=function(n){return n instanceof S?n:new S(function(i){i(n)})};S.reject=function(n){return new S(function(i,u){u(n)})};S.all=function(n){return new S(function(i,u){var c=n.length,b=0,h=[];if(n.length===0)i([]);else for(var o=0;o<n.length;o++)(function(s){function l(y){b++,h[s]=y,b===c&&i(h)}n[s]!=null&&(typeof n[s]=="object"||typeof n[s]=="function")&&typeof n[s].then=="function"?n[s].then(l,u):l(n[s])})(o)})};S.race=function(n){return new S(function(i,u){for(var c=0;c<n.length;c++)n[c].then(i,u)})};at.exports=S});var Se=O((Ur,he)=>{"use strict";var fe=_e();typeof window!="undefined"?(typeof window.Promise=="undefined"?window.Promise=fe:window.Promise.prototype.finally||(window.Promise.prototype.finally=fe.prototype.finally),he.exports=window.Promise):typeof global!="undefined"?(typeof global.Promise=="undefined"?global.Promise=fe:global.Promise.prototype.finally||(global.Promise.prototype.finally=fe.prototype.finally),he.exports=global.Promise):he.exports=fe});var ut=O((Fr,ft)=>{"use strict";var ie=Z();ft.exports=function(n){var i=n&&n.document,u,c={svg:"http://www.w3.org/2000/svg",math:"http://www.w3.org/1998/Math/MathML"};function b(t){return t.attrs&&t.attrs.xmlns||c[t.tag]}function h(t,e){if(t.state!==e)throw new Error("`vnode.state` must not be modified")}function o(t){var e=t.state;try{return this.apply(e,arguments)}finally{h(t,e)}}function s(){try{return i.activeElement}catch(t){return null}}function l(t,e,r,a,f,p,P){for(var N=r;N<a;N++){var q=e[N];q!=null&&y(t,q,f,P,p)}}function y(t,e,r,a,f){var p=e.tag;if(typeof p=="string")switch(e.state={},e.attrs!=null&&Pe(e.attrs,e,r),p){case"#":g(t,e,f);break;case"<":E(t,e,a,f);break;case"[":m(t,e,r,a,f);break;default:C(t,e,r,a,f)}else d(t,e,r,a,f)}function g(t,e,r){e.dom=i.createTextNode(e.children),v(t,e.dom,r)}var w={caption:"table",thead:"table",tbody:"table",tfoot:"table",tr:"tbody",th:"tr",td:"tr",colgroup:"table",col:"colgroup"};function E(t,e,r,a){var f=e.children.match(/^\s*?<(\w+)/im)||[],p=i.createElement(w[f[1]]||"div");r==="http://www.w3.org/2000/svg"?(p.innerHTML='<svg xmlns="http://www.w3.org/2000/svg">'+e.children+"</svg>",p=p.firstChild):p.innerHTML=e.children,e.dom=p.firstChild,e.domSize=p.childNodes.length,e.instance=[];for(var P=i.createDocumentFragment(),N;N=p.firstChild;)e.instance.push(N),P.appendChild(N);v(t,P,a)}function m(t,e,r,a,f){var p=i.createDocumentFragment();if(e.children!=null){var P=e.children;l(p,P,0,P.length,r,null,a)}e.dom=p.firstChild,e.domSize=p.childNodes.length,v(t,p,f)}function C(t,e,r,a,f){var p=e.tag,P=e.attrs,N=P&&P.is;a=b(e)||a;var q=a?N?i.createElementNS(a,p,{is:N}):i.createElementNS(a,p):N?i.createElement(p,{is:N}):i.createElement(p);if(e.dom=q,P!=null&&_t(e,P,a),v(t,q,f),!ee(e)&&(e.text!=null&&(e.text!==""?q.textContent=e.text:e.children=[ie("#",void 0,void 0,e.text,void 0,void 0)]),e.children!=null)){var A=e.children;l(q,A,0,A.length,r,null,a),e.tag==="select"&&P!=null&&Mt(e,P)}}function x(t,e){var r;if(typeof t.tag.view=="function"){if(t.state=Object.create(t.tag),r=t.state.view,r.$$reentrantLock$$!=null)return;r.$$reentrantLock$$=!0}else{if(t.state=void 0,r=t.tag,r.$$reentrantLock$$!=null)return;r.$$reentrantLock$$=!0,t.state=t.tag.prototype!=null&&typeof t.tag.prototype.view=="function"?new t.tag(t):t.tag(t)}if(Pe(t.state,t,e),t.attrs!=null&&Pe(t.attrs,t,e),t.instance=ie.normalize(o.call(t.state.view,t)),t.instance===t)throw Error("A view cannot return the vnode it received as argument");r.$$reentrantLock$$=null}function d(t,e,r,a,f){x(e,r),e.instance!=null?(y(t,e.instance,r,a,f),e.dom=e.instance.dom,e.domSize=e.dom!=null?e.instance.domSize:0):e.domSize=0}function T(t,e,r,a,f,p){if(!(e===r||e==null&&r==null))if(e==null||e.length===0)l(t,r,0,r.length,a,f,p);else if(r==null||r.length===0)G(t,e,0,e.length);else{var P=e[0]!=null&&e[0].key!=null,N=r[0]!=null&&r[0].key!=null,q=0,A=0;if(!P)for(;A<e.length&&e[A]==null;)A++;if(!N)for(;q<r.length&&r[q]==null;)q++;if(N===null&&P==null)return;if(P!==N)G(t,e,A,e.length),l(t,r,q,r.length,a,f,p);else if(N){for(var Q=e.length-1,_=r.length-1,oe,V,L,U,z,Te;Q>=A&&_>=q&&(U=e[Q],z=r[_],U.key===z.key);)U!==z&&D(t,U,z,a,f,p),z.dom!=null&&(f=z.dom),Q--,_--;for(;Q>=A&&_>=q&&(V=e[A],L=r[q],V.key===L.key);)A++,q++,V!==L&&D(t,V,L,a,B(e,A,f),p);for(;Q>=A&&_>=q&&!(q===_||V.key!==z.key||U.key!==L.key);)Te=B(e,A,f),J(t,U,Te),U!==L&&D(t,U,L,a,Te,p),++q<=--_&&J(t,V,f),V!==z&&D(t,V,z,a,f,p),z.dom!=null&&(f=z.dom),A++,Q--,U=e[Q],z=r[_],V=e[A],L=r[q];for(;Q>=A&&_>=q&&U.key===z.key;)U!==z&&D(t,U,z,a,f,p),z.dom!=null&&(f=z.dom),Q--,_--,U=e[Q],z=r[_];if(q>_)G(t,e,A,Q+1);else if(A>Q)l(t,r,q,_+1,a,f,p);else{var $t=f,Be=_-q+1,ae=new Array(Be),Ae=0,R=0,je=2147483647,ze=0,oe,Oe;for(R=0;R<Be;R++)ae[R]=-1;for(R=_;R>=q;R--){oe==null&&(oe=X(e,A,Q+1)),z=r[R];var re=oe[z.key];re!=null&&(je=re<je?re:-1,ae[R-q]=re,U=e[re],e[re]=null,U!==z&&D(t,U,z,a,f,p),z.dom!=null&&(f=z.dom),ze++)}if(f=$t,ze!==Q-A+1&&G(t,e,A,Q+1),ze===0)l(t,r,q,_+1,a,f,p);else if(je===-1)for(Oe=k(ae),Ae=Oe.length-1,R=_;R>=q;R--)L=r[R],ae[R-q]===-1?y(t,L,a,p,f):Oe[Ae]===R-q?Ae--:J(t,L,f),L.dom!=null&&(f=r[R].dom);else for(R=_;R>=q;R--)L=r[R],ae[R-q]===-1&&y(t,L,a,p,f),L.dom!=null&&(f=r[R].dom)}}else{var de=e.length<r.length?e.length:r.length;for(q=q<A?q:A;q<de;q++)V=e[q],L=r[q],!(V===L||V==null&&L==null)&&(V==null?y(t,L,a,p,B(e,q+1,f)):L==null?ce(t,V):D(t,V,L,a,B(e,q+1,f),p));e.length>de&&G(t,e,q,e.length),r.length>de&&l(t,r,q,r.length,a,f,p)}}}function D(t,e,r,a,f,p){var P=e.tag,N=r.tag;if(P===N){if(r.state=e.state,r.events=e.events,Vt(r,e))return;if(typeof P=="string")switch(r.attrs!=null&&Ne(r.attrs,r,a),P){case"#":W(e,r);break;case"<":Y(t,e,r,p,f);break;case"[":I(t,e,r,a,f,p);break;default:j(e,r,a,p)}else H(t,e,r,a,f,p)}else ce(t,e),y(t,r,a,p,f)}function W(t,e){t.children.toString()!==e.children.toString()&&(t.dom.nodeValue=e.children),e.dom=t.dom}function Y(t,e,r,a,f){e.children!==r.children?(Ve(t,e),E(t,r,a,f)):(r.dom=e.dom,r.domSize=e.domSize,r.instance=e.instance)}function I(t,e,r,a,f,p){T(t,e.children,r.children,a,f,p);var P=0,N=r.children;if(r.dom=null,N!=null){for(var q=0;q<N.length;q++){var A=N[q];A!=null&&A.dom!=null&&(r.dom==null&&(r.dom=A.dom),P+=A.domSize||1)}P!==1&&(r.domSize=P)}}function j(t,e,r,a){var f=e.dom=t.dom;a=b(e)||a,e.tag==="textarea"&&(e.attrs==null&&(e.attrs={}),e.text!=null&&(e.attrs.value=e.text,e.text=void 0)),Ht(e,t.attrs,e.attrs,a),ee(e)||(t.text!=null&&e.text!=null&&e.text!==""?t.text.toString()!==e.text.toString()&&(t.dom.firstChild.nodeValue=e.text):(t.text!=null&&(t.children=[ie("#",void 0,void 0,t.text,void 0,t.dom.firstChild)]),e.text!=null&&(e.children=[ie("#",void 0,void 0,e.text,void 0,void 0)]),T(f,t.children,e.children,r,null,a)))}function H(t,e,r,a,f,p){if(r.instance=ie.normalize(o.call(r.state.view,r)),r.instance===r)throw Error("A view cannot return the vnode it received as argument");Ne(r.state,r,a),r.attrs!=null&&Ne(r.attrs,r,a),r.instance!=null?(e.instance==null?y(t,r.instance,a,p,f):D(t,e.instance,r.instance,a,f,p),r.dom=r.instance.dom,r.domSize=r.instance.domSize):e.instance!=null?(ce(t,e.instance),r.dom=void 0,r.domSize=0):(r.dom=e.dom,r.domSize=e.domSize)}function X(t,e,r){for(var a=Object.create(null);e<r;e++){var f=t[e];if(f!=null){var p=f.key;p!=null&&(a[p]=e)}}return a}var K=[];function k(t){for(var e=[0],r=0,a=0,f=0,p=K.length=t.length,f=0;f<p;f++)K[f]=t[f];for(var f=0;f<p;++f)if(t[f]!==-1){var P=e[e.length-1];if(t[P]<t[f]){K[f]=P,e.push(f);continue}for(r=0,a=e.length-1;r<a;){var N=(r>>>1)+(a>>>1)+(r&a&1);t[e[N]]<t[f]?r=N+1:a=N}t[f]<t[e[r]]&&(r>0&&(K[f]=e[r-1]),e[r]=f)}for(r=e.length,a=e[r-1];r-- >0;)e[r]=a,a=K[a];return K.length=0,e}function B(t,e,r){for(;e<t.length;e++)if(t[e]!=null&&t[e].dom!=null)return t[e].dom;return r}function J(t,e,r){var a=i.createDocumentFragment();le(t,a,e),v(t,a,r)}function le(t,e,r){for(;r.dom!=null&&r.dom.parentNode===t;){if(typeof r.tag!="string"){if(r=r.instance,r!=null)continue}else if(r.tag==="<")for(var a=0;a<r.instance.length;a++)e.appendChild(r.instance[a]);else if(r.tag!=="[")e.appendChild(r.dom);else if(r.children.length===1){if(r=r.children[0],r!=null)continue}else for(var a=0;a<r.children.length;a++){var f=r.children[a];f!=null&&le(t,e,f)}break}}function v(t,e,r){r!=null?t.insertBefore(e,r):t.appendChild(e)}function ee(t){if(t.attrs==null||t.attrs.contenteditable==null&&t.attrs.contentEditable==null)return!1;var e=t.children;if(e!=null&&e.length===1&&e[0].tag==="<"){var r=e[0].children;t.dom.innerHTML!==r&&(t.dom.innerHTML=r)}else if(t.text!=null||e!=null&&e.length!==0)throw new Error("Child node of a contenteditable must be trusted");return!0}function G(t,e,r,a){for(var f=r;f<a;f++){var p=e[f];p!=null&&ce(t,p)}}function ce(t,e){var r=0,a=e.state,f,p;if(typeof e.tag!="string"&&typeof e.state.onbeforeremove=="function"){var P=o.call(e.state.onbeforeremove,e);P!=null&&typeof P.then=="function"&&(r=1,f=P)}if(e.attrs&&typeof e.attrs.onbeforeremove=="function"){var P=o.call(e.attrs.onbeforeremove,e);P!=null&&typeof P.then=="function"&&(r|=2,p=P)}if(h(e,a),!r)se(e),be(t,e);else{if(f!=null){var N=function(){r&1&&(r&=2,r||q())};f.then(N,N)}if(p!=null){var N=function(){r&2&&(r&=1,r||q())};p.then(N,N)}}function q(){h(e,a),se(e),be(t,e)}}function Ve(t,e){for(var r=0;r<e.instance.length;r++)t.removeChild(e.instance[r])}function be(t,e){for(;e.dom!=null&&e.dom.parentNode===t;){if(typeof e.tag!="string"){if(e=e.instance,e!=null)continue}else if(e.tag==="<")Ve(t,e);else{if(e.tag!=="["&&(t.removeChild(e.dom),!Array.isArray(e.children)))break;if(e.children.length===1){if(e=e.children[0],e!=null)continue}else for(var r=0;r<e.children.length;r++){var a=e.children[r];a!=null&&be(t,a)}}break}}function se(t){if(typeof t.tag!="string"&&typeof t.state.onremove=="function"&&o.call(t.state.onremove,t),t.attrs&&typeof t.attrs.onremove=="function"&&o.call(t.attrs.onremove,t),typeof t.tag!="string")t.instance!=null&&se(t.instance);else{var e=t.children;if(Array.isArray(e))for(var r=0;r<e.length;r++){var a=e[r];a!=null&&se(a)}}}function _t(t,e,r){for(var a in e)xe(t,a,null,e[a],r)}function xe(t,e,r,a,f){if(!(e==="key"||e==="is"||a==null||qe(e)||r===a&&!Ut(t,e)&&typeof a!="object")){if(e[0]==="o"&&e[1]==="n")return Je(t,e,a);if(e.slice(0,6)==="xlink:")t.dom.setAttributeNS("http://www.w3.org/1999/xlink",e.slice(6),a);else if(e==="style")Ke(t.dom,r,a);else if($e(t,e,f)){if(e==="value"&&((t.tag==="input"||t.tag==="textarea")&&t.dom.value===""+a&&t.dom===s()||t.tag==="select"&&r!==null&&t.dom.value===""+a||t.tag==="option"&&r!==null&&t.dom.value===""+a))return;t.tag==="input"&&e==="type"?t.dom.setAttribute(e,a):t.dom[e]=a}else typeof a=="boolean"?a?t.dom.setAttribute(e,""):t.dom.removeAttribute(e):t.dom.setAttribute(e==="className"?"class":e,a)}}function St(t,e,r,a){if(!(e==="key"||e==="is"||r==null||qe(e)))if(e[0]==="o"&&e[1]==="n"&&!qe(e))Je(t,e,void 0);else if(e==="style")Ke(t.dom,r,null);else if($e(t,e,a)&&e!=="className"&&!(e==="value"&&(t.tag==="option"||t.tag==="select"&&t.dom.selectedIndex===-1&&t.dom===s()))&&!(t.tag==="input"&&e==="type"))t.dom[e]=null;else{var f=e.indexOf(":");f!==-1&&(e=e.slice(f+1)),r!==!1&&t.dom.removeAttribute(e==="className"?"class":e)}}function Mt(t,e){if("value"in e)if(e.value===null)t.dom.selectedIndex!==-1&&(t.dom.value=null);else{var r=""+e.value;(t.dom.value!==r||t.dom.selectedIndex===-1)&&(t.dom.value=r)}"selectedIndex"in e&&xe(t,"selectedIndex",null,e.selectedIndex,void 0)}function Ht(t,e,r,a){if(r!=null)for(var f in r)xe(t,f,e&&e[f],r[f],a);var p;if(e!=null)for(var f in e)(p=e[f])!=null&&(r==null||r[f]==null)&&St(t,f,p,a)}function Ut(t,e){return e==="value"||e==="checked"||e==="selectedIndex"||e==="selected"&&t.dom===s()||t.tag==="option"&&t.dom.parentNode===i.activeElement}function qe(t){return t==="oninit"||t==="oncreate"||t==="onupdate"||t==="onremove"||t==="onbeforeremove"||t==="onbeforeupdate"}function $e(t,e,r){return r===void 0&&(t.tag.indexOf("-")>-1||t.attrs!=null&&t.attrs.is||e!=="href"&&e!=="list"&&e!=="form"&&e!=="width"&&e!=="height")&&e in t.dom}var Ft=/[A-Z]/g;function Qt(t){return"-"+t.toLowerCase()}function Ce(t){return t[0]==="-"&&t[1]==="-"?t:t==="cssFloat"?"float":t.replace(Ft,Qt)}function Ke(t,e,r){if(e!==r)if(r==null)t.style.cssText="";else if(typeof r!="object")t.style.cssText=r;else if(e==null||typeof e!="object"){t.style.cssText="";for(var a in r){var f=r[a];f!=null&&t.style.setProperty(Ce(a),String(f))}}else{for(var a in r){var f=r[a];f!=null&&(f=String(f))!==String(e[a])&&t.style.setProperty(Ce(a),f)}for(var a in e)e[a]!=null&&r[a]==null&&t.style.removeProperty(Ce(a))}}function Ee(){this._=u}Ee.prototype=Object.create(null),Ee.prototype.handleEvent=function(t){var e=this["on"+t.type],r;typeof e=="function"?r=e.call(t.currentTarget,t):typeof e.handleEvent=="function"&&e.handleEvent(t),this._&&t.redraw!==!1&&(0,this._)(),r===!1&&(t.preventDefault(),t.stopPropagation())};function Je(t,e,r){if(t.events!=null){if(t.events[e]===r)return;r!=null&&(typeof r=="function"||typeof r=="object")?(t.events[e]==null&&t.dom.addEventListener(e.slice(2),t.events,!1),t.events[e]=r):(t.events[e]!=null&&t.dom.removeEventListener(e.slice(2),t.events,!1),t.events[e]=void 0)}else r!=null&&(typeof r=="function"||typeof r=="object")&&(t.events=new Ee,t.dom.addEventListener(e.slice(2),t.events,!1),t.events[e]=r)}function Pe(t,e,r){typeof t.oninit=="function"&&o.call(t.oninit,e),typeof t.oncreate=="function"&&r.push(o.bind(t.oncreate,e))}function Ne(t,e,r){typeof t.onupdate=="function"&&r.push(o.bind(t.onupdate,e))}function Vt(t,e){do{if(t.attrs!=null&&typeof t.attrs.onbeforeupdate=="function"){var r=o.call(t.attrs.onbeforeupdate,t,e);if(r!==void 0&&!r)break}if(typeof t.tag!="string"&&typeof t.state.onbeforeupdate=="function"){var r=o.call(t.state.onbeforeupdate,t,e);if(r!==void 0&&!r)break}return!1}while(!1);return t.dom=e.dom,t.domSize=e.domSize,t.instance=e.instance,t.attrs=e.attrs,t.children=e.children,t.text=e.text,!0}return function(t,e,r){if(!t)throw new TypeError("Ensure the DOM element being passed to m.route/m.mount/m.render is not undefined.");var a=[],f=s(),p=t.namespaceURI;t.vnodes==null&&(t.textContent=""),e=ie.normalizeChildren(Array.isArray(e)?e:[e]);var P=u;try{u=typeof r=="function"?r:void 0,T(t,t.vnodes,e,a,null,p==="http://www.w3.org/1999/xhtml"?void 0:p)}finally{u=P}t.vnodes=e,f!=null&&s()!==f&&typeof f.focus=="function"&&f.focus();for(var N=0;N<a.length;N++)a[N]()}}});var Me=O((Qr,lt)=>{"use strict";lt.exports=ut()(window)});var ot=O((Vr,ct)=>{"use strict";var st=Z();ct.exports=function(n,i,u){var c=[],b=!1,h=!1;function o(){if(b)throw new Error("Nested m.redraw.sync() call");b=!0;for(var y=0;y<c.length;y+=2)try{n(c[y],st(c[y+1]),s)}catch(g){u.error(g)}b=!1}function s(){h||(h=!0,i(function(){h=!1,o()}))}s.sync=o;function l(y,g){if(g!=null&&g.view==null&&typeof g!="function")throw new TypeError("m.mount(element, component) expects a component, not a vnode");var w=c.indexOf(y);w>=0&&(c.splice(w,2),n(y,[],s)),g!=null&&(c.push(y,g),n(y,st(g),s))}return{mount:l,redraw:s}}});var pe=O(($r,ht)=>{"use strict";var ur=Me();ht.exports=ot()(ur,requestAnimationFrame,console)});var He=O((Kr,pt)=>{"use strict";pt.exports=function(n){if(Object.prototype.toString.call(n)!=="[object Object]")return"";var i=[];for(var u in n)c(u,n[u]);return i.join("&");function c(b,h){if(Array.isArray(h))for(var o=0;o<h.length;o++)c(b+"["+o+"]",h[o]);else if(Object.prototype.toString.call(h)==="[object Object]")for(var o in h)c(b+"["+o+"]",h[o]);else i.push(encodeURIComponent(b)+(h!=null&&h!==""?"="+encodeURIComponent(h):""))}}});var Ue=O((Jr,mt)=>{"use strict";mt.exports=Object.assign||function(n,i){i&&Object.keys(i).forEach(function(u){n[u]=i[u]})}});var me=O((Br,yt)=>{"use strict";var lr=He(),cr=Ue();yt.exports=function(n,i){if(/:([^\/\.-]+)(\.{3})?:/.test(n))throw new SyntaxError("Template parameter names *must* be separated");if(i==null)return n;var u=n.indexOf("?"),c=n.indexOf("#"),b=c<0?n.length:c,h=u<0?b:u,o=n.slice(0,h),s={};cr(s,i);var l=o.replace(/:([^\/\.-]+)(\.{3})?/g,function(x,d,T){return delete s[d],i[d]==null?x:T?i[d]:encodeURIComponent(String(i[d]))}),y=l.indexOf("?"),g=l.indexOf("#"),w=g<0?l.length:g,E=y<0?w:y,m=l.slice(0,E);u>=0&&(m+=n.slice(u,b)),y>=0&&(m+=(u<0?"?":"&")+l.slice(y,w));var C=lr(s);return C&&(m+=(u<0&&y<0?"?":"&")+C),c>=0&&(m+=n.slice(c)),g>=0&&(m+=(c<0?"":"&")+l.slice(g)),m}});var wt=O((Gr,gt)=>{"use strict";var sr=me();gt.exports=function(n,i,u){var c=0;function b(s){return new i(s)}b.prototype=i.prototype,b.__proto__=i;function h(s){return function(l,y){typeof l!="string"?(y=l,l=l.url):y==null&&(y={});var g=new i(function(C,x){s(sr(l,y.params),y,function(d){if(typeof y.type=="function")if(Array.isArray(d))for(var T=0;T<d.length;T++)d[T]=new y.type(d[T]);else d=new y.type(d);C(d)},x)});if(y.background===!0)return g;var w=0;function E(){--w==0&&typeof u=="function"&&u()}return m(g);function m(C){var x=C.then;return C.constructor=b,C.then=function(){w++;var d=x.apply(C,arguments);return d.then(E,function(T){if(E(),w===0)throw T}),m(d)},C}}}function o(s,l){for(var y in s.headers)if({}.hasOwnProperty.call(s.headers,y)&&l.test(y))return!0;return!1}return{request:h(function(s,l,y,g){var w=l.method!=null?l.method.toUpperCase():"GET",E=l.body,m=(l.serialize==null||l.serialize===JSON.serialize)&&!(E instanceof n.FormData),C=l.responseType||(typeof l.extract=="function"?"":"json"),x=new n.XMLHttpRequest,d=!1,T=x,D,W=x.abort;x.abort=function(){d=!0,W.call(this)},x.open(w,s,l.async!==!1,typeof l.user=="string"?l.user:void 0,typeof l.password=="string"?l.password:void 0),m&&E!=null&&!o(l,/^content-type$/i)&&x.setRequestHeader("Content-Type","application/json; charset=utf-8"),typeof l.deserialize!="function"&&!o(l,/^accept$/i)&&x.setRequestHeader("Accept","application/json, text/*"),l.withCredentials&&(x.withCredentials=l.withCredentials),l.timeout&&(x.timeout=l.timeout),x.responseType=C;for(var Y in l.headers)({}).hasOwnProperty.call(l.headers,Y)&&x.setRequestHeader(Y,l.headers[Y]);x.onreadystatechange=function(I){if(!d&&I.target.readyState===4)try{var j=I.target.status>=200&&I.target.status<300||I.target.status===304||/^file:\/\//i.test(s),H=I.target.response,X;if(C==="json"?!I.target.responseType&&typeof l.extract!="function"&&(H=JSON.parse(I.target.responseText)):(!C||C==="text")&&H==null&&(H=I.target.responseText),typeof l.extract=="function"?(H=l.extract(I.target,l),j=!0):typeof l.deserialize=="function"&&(H=l.deserialize(H)),j)y(H);else{try{X=I.target.responseText}catch(k){X=H}var K=new Error(X);K.code=I.target.status,K.response=H,g(K)}}catch(k){g(k)}},typeof l.config=="function"&&(x=l.config(x,l,s)||x,x!==T&&(D=x.abort,x.abort=function(){d=!0,D.call(this)})),E==null?x.send():typeof l.serialize=="function"?x.send(l.serialize(E)):E instanceof n.FormData?x.send(E):x.send(JSON.stringify(E))}),jsonp:h(function(s,l,y,g){var w=l.callbackName||"_mithril_"+Math.round(Math.random()*1e16)+"_"+c++,E=n.document.createElement("script");n[w]=function(m){delete n[w],E.parentNode.removeChild(E),y(m)},E.onerror=function(){delete n[w],E.parentNode.removeChild(E),g(new Error("JSONP request failed"))},E.src=s+(s.indexOf("?")<0?"?":"&")+encodeURIComponent(l.callbackKey||"callback")+"="+encodeURIComponent(w),n.document.documentElement.appendChild(E)})}}});var xt=O((Xr,bt)=>{"use strict";var or=Se(),hr=pe();bt.exports=wt()(window,or,hr.redraw)});var Fe=O((Zr,qt)=>{"use strict";qt.exports=function(n){if(n===""||n==null)return{};n.charAt(0)==="?"&&(n=n.slice(1));for(var i=n.split("&"),u={},c={},b=0;b<i.length;b++){var h=i[b].split("="),o=decodeURIComponent(h[0]),s=h.length===2?decodeURIComponent(h[1]):"";s==="true"?s=!0:s==="false"&&(s=!1);var l=o.split(/\]\[?|\[/),y=c;o.indexOf("[")>-1&&l.pop();for(var g=0;g<l.length;g++){var w=l[g],E=l[g+1],m=E==""||!isNaN(parseInt(E,10));if(w===""){var o=l.slice(0,g).join();u[o]==null&&(u[o]=Array.isArray(y)?y.length:0),w=u[o]++}else if(w==="__proto__")break;if(g===l.length-1)y[w]=s;else{var C=Object.getOwnPropertyDescriptor(y,w);C!=null&&(C=C.value),C==null&&(y[w]=C=m?[]:{}),y=C}}}return c}});var ye=O((Wr,Ct)=>{"use strict";var pr=Fe();Ct.exports=function(n){var i=n.indexOf("?"),u=n.indexOf("#"),c=u<0?n.length:u,b=i<0?c:i,h=n.slice(0,b).replace(/\/{2,}/g,"/");return h?(h[0]!=="/"&&(h="/"+h),h.length>1&&h[h.length-1]==="/"&&(h=h.slice(0,-1))):h="/",{path:h,params:i<0?{}:pr(n.slice(i+1,c))}}});var Pt=O((Yr,Et)=>{"use strict";var mr=ye();Et.exports=function(n){var i=mr(n),u=Object.keys(i.params),c=[],b=new RegExp("^"+i.path.replace(/:([^\/.-]+)(\.{3}|\.(?!\.)|-)?|[\\^$*+.()|\[\]{}]/g,function(h,o,s){return o==null?"\\"+h:(c.push({k:o,r:s==="..."}),s==="..."?"(.*)":s==="."?"([^/]+)\\.":"([^/]+)"+(s||""))})+"$");return function(h){for(var o=0;o<u.length;o++)if(i.params[u[o]]!==h.params[u[o]])return!1;if(!c.length)return b.test(h.path);var s=b.exec(h.path);if(s==null)return!1;for(var o=0;o<c.length;o++)h.params[c[o].k]=c[o].r?s[o+1]:decodeURIComponent(s[o+1]);return!0}}});var At=O((kr,Nt)=>{"use strict";var yr=Z(),gr=De(),wr=Se(),br=me(),dt=ye(),xr=Pt(),Tt=Ue(),Qe={};Nt.exports=function(n,i){var u;function c(w,E,m){if(w=br(w,E),u!=null){u();var C=m?m.state:null,x=m?m.title:null;m&&m.replace?n.history.replaceState(C,x,g.prefix+w):n.history.pushState(C,x,g.prefix+w)}else n.location.href=g.prefix+w}var b=Qe,h,o,s,l,y=g.SKIP={};function g(w,E,m){if(w==null)throw new Error("Ensure the DOM element that was passed to `m.route` is not undefined");var C=0,x=Object.keys(m).map(function(j){if(j[0]!=="/")throw new SyntaxError("Routes must start with a `/`");if(/:([^\/\.-]+)(\.{3})?:/.test(j))throw new SyntaxError("Route parameter names must be separated with either `/`, `.`, or `-`");return{route:j,component:m[j],check:xr(j)}}),d=typeof setImmediate=="function"?setImmediate:setTimeout,T=wr.resolve(),D=!1,W;if(u=null,E!=null){var Y=dt(E);if(!x.some(function(j){return j.check(Y)}))throw new ReferenceError("Default route doesn't match any known routes")}function I(){D=!1;var j=n.location.hash;g.prefix[0]!=="#"&&(j=n.location.search+j,g.prefix[0]!=="?"&&(j=n.location.pathname+j,j[0]!=="/"&&(j="/"+j)));var H=j.concat().replace(/(?:%[a-f89][a-f0-9])+/gim,decodeURIComponent).slice(g.prefix.length),X=dt(H);Tt(X.params,n.history.state);function K(){if(H===E)throw new Error("Could not resolve default route "+E);c(E,null,{replace:!0})}k(0);function k(B){for(;B<x.length;B++)if(x[B].check(X)){var J=x[B].component,le=x[B].route,v=J,ee=l=function(G){if(ee===l){if(G===y)return k(B+1);h=G!=null&&(typeof G.view=="function"||typeof G=="function")?G:"div",o=X.params,s=H,l=null,b=J.render?J:null,C===2?i.redraw():(C=2,i.redraw.sync())}};J.view||typeof J=="function"?(J={},ee(v)):J.onmatch?T.then(function(){return J.onmatch(X.params,H,le)}).then(ee,K):ee("div");return}K()}}return u=function(){D||(D=!0,d(I))},typeof n.history.pushState=="function"?(W=function(){n.removeEventListener("popstate",u,!1)},n.addEventListener("popstate",u,!1)):g.prefix[0]==="#"&&(u=null,W=function(){n.removeEventListener("hashchange",I,!1)},n.addEventListener("hashchange",I,!1)),i.mount(w,{onbeforeupdate:function(){return C=C?2:1,!(!C||Qe===b)},oncreate:I,onremove:W,view:function(){if(!(!C||Qe===b)){var j=[yr(h,o.key,o)];return b&&(j=b.render(j[0])),j}}})}return g.set=function(w,E,m){l!=null&&(m=m||{},m.replace=!0),l=null,c(w,E,m)},g.get=function(){return s},g.prefix="#!",g.Link={view:function(w){var E=w.attrs.options,m={},C,x;Tt(m,w.attrs),m.selector=m.options=m.key=m.oninit=m.oncreate=m.onbeforeupdate=m.onupdate=m.onbeforeremove=m.onremove=null;var d=gr(w.attrs.selector||"a",m,w.children);return(d.attrs.disabled=Boolean(d.attrs.disabled))?(d.attrs.href=null,d.attrs["aria-disabled"]="true",d.attrs.onclick=null):(C=d.attrs.onclick,x=d.attrs.href,d.attrs.href=g.prefix+x,d.attrs.onclick=function(T){var D;typeof C=="function"?D=C.call(T.currentTarget,T):C==null||typeof C!="object"||typeof C.handleEvent=="function"&&C.handleEvent(T),D!==!1&&!T.defaultPrevented&&(T.button===0||T.which===0||T.which===1)&&(!T.currentTarget.target||T.currentTarget.target==="_self")&&!T.ctrlKey&&!T.metaKey&&!T.shiftKey&&!T.altKey&&(T.preventDefault(),T.redraw=!1,g.set(x,null,E))}),d}},g.param=function(w){return o&&w!=null?o[w]:o},g}});var zt=O((vr,jt)=>{"use strict";var qr=pe();jt.exports=At()(window,qr)});var Dt=O((en,Ot)=>{"use strict";var ge=it(),Rt=xt(),Lt=pe(),F=function(){return ge.apply(this,arguments)};F.m=ge;F.trust=ge.trust;F.fragment=ge.fragment;F.mount=Lt.mount;F.route=zt();F.render=Me();F.redraw=Lt.redraw;F.request=Rt.request;F.jsonp=Rt.jsonp;F.parseQueryString=Fe();F.buildQueryString=He();F.parsePathname=ye();F.buildPathname=me();F.vnode=Z();F.PromisePolyfill=_e();Ot.exports=F});var M=Yt(Dt()),Cr=document.querySelector("nav .search"),It=document.createElement("div");document.querySelector("main").insertBefore(It,document.querySelector(".header"));var $={showingSearchDialog:!1,searchResults:[],searchError:null,searchQuery:""},Er=([n,...i])=>n.toLowerCase()+i.join(""),Pr=([n,...i])=>n.toUpperCase()+i.join(""),Nr=n=>n.split(/[ _]/).map(Er).join("_"),dr=n=>n.split(/[ _]/).map(Pr).join(" "),ue=(n,i)=>{let u=`/${encodeURIComponent(Nr(n))}`;return i&&(u+="/"+i),u},Tr=n=>{if(n.code===0)return;let i=`Server error ${n.code}`;n.message&&(i+=" "+n.message),alert(i)},Ar=n=>{let i=n.target.value;$.searchQuery=i,M.default.request({url:"/api/search",params:{q:i}}).then(u=>{typeof u=="string"?(console.log("ERR",u),$.searchError=u):($.searchResults=u,$.searchError=null)},u=>Tr)},we=dr(decodeURIComponent(/^\/([^/]+)/.exec(location.pathname)[1]).replace(/\+/g," ")),jr=n=>{if(n.keyCode===13){let i=$.searchResults.filter(u=>u.page!==we);i[0]&&(location.href=ue(i[0].page))}},zr={view:()=>M.default(".dialog.search",[M.default("h1","Search"),M.default("input[type=search]",{placeholder:"Query",oninput:Ar,onkeydown:jr,value:$.searchQuery,oncreate:({dom:n})=>n.focus()}),$.searchError&&M.default(".error",$.searchError),M.default("ul",$.searchResults.map(n=>M.default("li",[M.default(".flex-space",[M.default("a.wikilink",{href:ue(n.page)},n.page),M.default("",n.rank.toFixed(3))]),M.default("",n.snippet.map(i=>i[0]?M.default("span.highlight",i[1]):i[1]))])))])},Or={view:()=>M.default("",$.showingSearchDialog?M.default(zr):null)};Cr.addEventListener("click",n=>{$.showingSearchDialog=!$.showingSearchDialog,n.preventDefault(),M.default.redraw()});document.body.addEventListener("keydown",n=>{n.target===document.body&&(n.key==="e"?location.pathname=ue(we,"edit"):n.key==="v"?location.pathname=ue(we):n.key==="r"?location.pathname=ue(we,"revisions"):n.key==="/"&&($.showingSearchDialog=!$.showingSearchDialog,n.preventDefault(),M.default.redraw()))});M.default.mount(It,Or);})();
//# sourceMappingURL=client.js.map
