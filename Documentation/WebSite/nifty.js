/* Cleaned up from http://webdesign.html.it/articoli/leggi/528/more-nifty-corners/ */
function NiftyCheck()
{
  webapp_link();
  if (!document.getElementById || !document.createElement)
    return false;

  isXHTML=/html\:/.test(document.getElementsByTagName('body')[0].nodeName);
  if (Array.prototype.push==null)
  {
    Array.prototype.push=function()
    {
      this[this.length]=arguments[0];
      return this.length;
    }
  }
  return true;
}

function Rounded(selector,which,bk,color,opt)
{
  var i,prefixt,prefixb,cn="r",ecolor="",edges=false,eclass="",b=false,t=false;
  if (color == "transparent")
  {
    cn = cn+"x";
    ecolor = bk;
    bk = "transparent";
  }
  else if (opt && opt.indexOf("border") >= 0)
  {
    var optar = opt.split(" ");
    for (i=0; i<optar.length; i++)
      if (optar[i].indexOf("#") >= 0)
         ecolor = optar[i];
    if (ecolor=="") ecolor="#666";
    cn += "e";
    edges = true;
  }
  else if (opt && opt.indexOf("smooth") >= 0)
  {
    cn += "a";
    ecolor = Mix(bk,color);
  }

  if (opt && opt.indexOf("small") >= 0)
    cn+="s";

  prefixt=cn;
  prefixb=cn;
  if (which.indexOf("all") >= 0)
    t = b = true;
  else if (which.indexOf("top") >= 0)
    t = true;
  else if (which.indexOf("tl") >= 0)
  {
    t = true;
    if (which.indexOf("tr") < 0)
      prefixt += "l";
  }
  else if (which.indexOf("tr") >= 0)
  {
    t = true;
    prefixt += "r";
  }
  if (which.indexOf("bottom") >= 0)
    b = true;
  else if (which.indexOf("bl") >= 0)
  {
    b = true;
    if (which.indexOf("br") < 0)
      prefixb += "l";
  }
  else if (which.indexOf("br") >= 0)
  {
    b = true;
    prefixb += "r";
  }

  var v=getElementsBySelector(selector);
  var l=v.length;
  for(i=0;i<l;i++)
  {
    if (edges) AddBorder(v[i],ecolor);
    if (t) AddTop(v[i],bk,color,ecolor,prefixt);
    if (b) AddBottom(v[i],bk,color,ecolor,prefixb);
  }
}

function AddBorder(el,bc)
{
  var i;
  if (! el.passed)
  {
    if (el.childNodes.length==1 && el.childNodes[0].nodeType==3)
    {
      var t=el.firstChild.nodeValue;
      el.removeChild(el.lastChild);
      var d=CreateEl("span");
      d.style.display="block";
      d.appendChild(document.createTextNode(t));
      el.appendChild(d);
    }
    for(i=0;i<el.childNodes.length;i++)
      if(el.childNodes[i].nodeType==1)
      {
        el.childNodes[i].style.borderLeft="1px solid "+bc;
        el.childNodes[i].style.borderRight="1px solid "+bc;
      }
  }
  el.passed=true;
}
    
function AddTop(el,bk,color,bc,cn)
{
  var i,lim=4,d=CreateEl("b");

  if (cn.indexOf("s") >= 0)
    lim=2;
  d.className = bc ? "artop" : "rtop";
  d.style.backgroundColor = bk;
  for (i=1;i<=lim;i++)
  {
    var x=CreateEl("b");
    x.className=cn + i;
    x.style.backgroundColor=color;
    if (bc) x.style.borderColor=bc;
    d.appendChild(x);
  }
  el.style.paddingTop=0;
  el.insertBefore(d,el.firstChild);
}

function AddBottom(el,bk,color,bc,cn)
{
  var i,lim=4,d=CreateEl("b");

  if (cn.indexOf("s") >= 0)
    lim=2;
  d.className = bc ? "artop" : "rtop";
  d.style.backgroundColor = bk;
  for (i=lim;i>0;i--)
  {
    var x=CreateEl("b");
    x.className=cn + i;
    x.style.backgroundColor=color;
    if (bc) x.style.borderColor=bc;
    d.appendChild(x);
  }
  el.style.paddingBottom=0;
  el.appendChild(d);
}

function CreateEl(x)
{
  if(isXHTML)
    return document.createElementNS('http://www.w3.org/1999/xhtml',x);
  else
    return document.createElement(x);
}

function getElementsBySelector(selector)
{
  var result = [];
  var list = [document];
  var components = selector.split(" ");
  for (var i = 0; i < components.length; ++i)
  {
    list = getBySubSelector(list, components[i]);
  }
  return list;
}

function getBySubSelector(elements, selector)
{
  var result = [];
  for (var i = 0; i < elements.length; ++i)
  {
    var el = elements[i];
    var parts = selector.split("#");
    if (parts.length > 1)
    {
      var elt = el.getElementsById(parts[1])
                .getElementsByTagName(parts[0]);
      result.push(elt);
      continue;
    }

    parts = selector.split(".");
    if (parts.length > 1)
    {
      var elts = el.getElementsByTagName(parts[0]);
      for (var j = 0; j < elts.length; ++j)
	if (elts[j].className == parts[1])
	{
	  result.push(elts[j]);
	}
      continue;
    }

    var elts = el.getElementsByTagName(selector);
    for (var j = 0; j < elts.length; ++j)
      result.push(elts[j]);
  }
  return result;
}

function Mix(c1,c2)
{
  var r=new Array(3);
  var step1 = (c1.length==4 ? 1 : 2);
  var step2 = (c2.length==4 ? 1 : 2);
  for(var i=0;i<3;i++)
  {
    var x=parseInt(c1.substr(1+step1*i,step1),16);
    if(step1==1) x=16*x+x;
    var y=parseInt(c2.substr(1+step2*i,step2),16);
    if(step2==1) y=16*y+y;
    r[i]=Math.floor((x*50+y*50)/100);
  }
  return("#"+r[0].toString(16)+r[1].toString(16)+r[2].toString(16));
}

// Added by TW, to update the web-page without branching the code...
// insert a link to the next-gen website, flashing onto the screen a few seconds after the page appears...

webapp_link = function() {
  var makeLink = function() {
    var elList, el, tgt, child, uri;
    tgt = document.getElementById('nextgen-link');
    if ( tgt ) { return; }
    child = document.createElement('li');
    child.id = 'nextgen-link';
    elList = document.getElementsByClassName('catopt');
    try {
      el = elList[0].childNodes[1];
    } catch(ex) { /* cannot find element, abort! */ return; }
    uri = location.href;
    uri = uri.replace(/\/$/, '');
    uri = uri.replace(/\/[^/]*\/[^/]*::.*/,'');
    child.innerHTML = '<a href="'+uri+'/datasvc/app" title="Enter the next-gen website, enter the future!">Next-gen website</a>';
    el.appendChild(child);
    return child;
  };
  var fn = function() {
    var child = makeLink();
    var fade = function(element) {
      var col1 = col2 = 0;
      return function() {
        var c1 = col1.toString(16),
            c2 = col2.toString(16),
            str = '#ff',
            interval = 100,
            step = 16;
        if ( col1 > 15 ) {
          str = str + c1;
        } else {
          str = str + '0' + c1;
        }
        if ( col2 > 15 ) {
          str = str + c2;
        } else {
          str = str + '0' + c2;
        }
        element.style.backgroundColor = str;
        col1 = col1 + step;
        if ( col1 < 255 ) {
          setTimeout(fade,interval);
        }
        else
        {
          col1 = 255;
          col2 += step;
          if ( col2 < 255 ) { setTimeout(fade,interval); }
          else              { element.style.backgroundColor = ''; }
        }
      }
    }(child);
    fade();
  };
  var PhedexLoadCount = 0;
  if ( navigator.cookieEnabled ) {
    var cookie = document.cookie;
    if ( cookie ) {
      first = cookie.indexOf('PhedexLoadCount=');
      if ( cookie.match(/^PhedexLoadCount=(\d+)/) ) {
        PhedexLoadCount = RegExp.$1;
      }
    } else {
      PhedexLoadCount = 5;
    }
    if ( PhedexLoadCount ) {
      PhedexLoadCount--;
      var future = new Date();
      future.setDate(future.getDate() + 10);
      var tmp = 'PhedexLoadCount=' + encodeURI(PhedexLoadCount) + '; expires=' + future.toGMTString() + '; path=/';
      document.cookie = tmp;
    }
  }
  if ( PhedexLoadCount > 0 ) {
    setTimeout(fn,3000);
  } else {
    makeLink();
  }
};
