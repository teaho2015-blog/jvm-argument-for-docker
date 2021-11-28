<!doctype HTML>
<html>
<head>
<meta charset="utf-8" />
<meta content="width=device-width, initial-scale=1" name="viewport">
<link rel="icon" href="asset/t.png">
<title>Java9模块化</title>
<style>
body {
color: #333;
font-family: sans-serif;
font-size: 12pt;
line-height: 170%;
padding: 0 30px 0 270px;
}
header .banner {
margin: 0 0 1em 0;
}
header .banner, nav .banner {
color: #777;
font-size: 10pt;
font-weight: bold;
}
header h1 {
background: #4b4b4b;
border-radius: 4px;
color: #fff;
font-size: 24pt;
margin: 0;
padding: 1.2em 0;
text-align: center;
}
nav {
font-size: 10pt;
overflow-x: hidden;
overflow-y: auto;
position: fixed;
top: 0;
left: 0;
bottom: 0;
width: 240px;
}
nav .menubar {
border-bottom: solid 1px #ccc;
display: none;
height: 48px;
line-height: 48px;
padding: 0 10px;
}
nav .button {
background: #777;
border: 1px solid #333;
color: #fff;
font-size: 10pt;
font-weight: bold;
padding: 8px;
border-radius: 4px;
}
nav ul {
padding: 0 0 0 10px;
}
nav ul a {
color: #333;
text-decoration: none;
}
nav ul a:hover {
text-decoration: underline;
}
nav li {
line-height: 180%;
list-style: none;
margin: 0;
padding: 0;
}
nav .level2 {
font-size: 11pt;
font-weight: bold;
}
nav .level3 {
padding-left: 1em;
}
nav .level3:before { 
content: "» ";
}
nav .level4 {
padding-left: 2em;
}
nav .level4:before {
content: "› ";
}
nav .level5 {
	padding-left: 3em;
}
nav .level5:before {
	content: "› ";
}
article h2 {
border-bottom: dotted 1px #777;
font-size: 12pt;
line-height: 100%;
margin: 4em 0 1em 0;
padding: 0 0 0.3em 0;
}
article h3 {
font-size: 12pt;
line-height: 100%;
margin: 2em 0 1em 0;
padding: 0;
}
article h4 {
font-size: 12pt;
font-style:italic;
font-weight: normal;
line-height: 100%;
margin: 1.2em 0 1em 0;
padding: 0;
}
article a {
word-wrap:break-word;
}
article p {
margin: 1em 0;
}
article p code {
background: #eee;
border: 1px solid #ccc;
}
article p strong {
color: #f00;
}
article pre {
background: #eee;
border-left: solid 2px #3c0;
font-size: 10pt;
margin: 1em 0;
padding: 0 0 0 1em;
overflow-x: auto;
overflow-y: padding;
}
article img {
	max-width: 100%;
}
article blockquote {
background: #fff;
border: dashed 1px #777;
border-left: solid 2px #777;
color: #000;
margin: 0;
padding: 0 0 0 1em;
}
article ul, article ol {
padding-left: 2em;
}

body.disable{
	display: none;
}
footer {
border-top: 1px solid #ccc;
font-size: 10pt;
margin-top: 4em;
}
/*@media screen and (max-width: 768px) {
body {
padding: 0 10px 0 230px;
}
nav {
width: 230px;
}
}*/
@media (max-width: 768px) {
body {
padding: 64px 8px 0 8px;
}
header .banner {
display: block;
}
nav {

position: relative;
width: 100%;
}
nav .menubar {
display: block;
}
nav .banner {
float: right;
}
nav ul {
background: #fff;
display: block;
font-size: 9pt;
margin: 0;
padding: 0 0 0 8px;
}
nav .level2 {
font-size: 16pt;
font-weight: bold;
}
nav li {
line-height: 240%;
}
.index nav ul {
display: block;
}
.index article {
display: none;
}
}
</style>
<!-- Global site tag (gtag.js) - Google Analytics -->
<!-- TODO 修改id -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-QXVZLLWHZV"></script>
<script>
	window.dataLayer = window.dataLayer || [];
	function gtag(){dataLayer.push(arguments);}
	gtag('js', new Date());

	gtag('config', 'G-QXVZLLWHZV');
</script>
</head>
<body class="">
<header>
	<x-markdown src="section/header.md" />
</header>
<nav>
<x-index />
</nav>
<article>
	<x-markdown src="section/java.md" />
</article>
<!--<footer>
	place license markdown file
</footer>-->
</body>
<script>


    function getQueryString(name) {
        let reg = new RegExp("(^|&)" + name + "=([^&]*)(&|$)", "i");
        let r = window.location.search.substr(1).match(reg);
        if (r != null) {
            return decodeURIComponent(r[2]);
        };
        return null;
    }

    ;(function () {
        if(getQueryString("key") === "interview") {
            document.getElementsByTagName("body")[0].className = "";

        }
	})();

</script>
</html>