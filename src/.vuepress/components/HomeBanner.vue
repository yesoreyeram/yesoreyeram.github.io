<template>
  <div id="homebanner">
    <h2 style="border:none;">Sriramajeyam Sugumaran <span style="color:#d2d2d2;font-size:80%;">@ yesoreyeram</span></h2>

    <div class="about">
        <div class="aboutleft">
            <p>Hello..! Welcome to my site. I am <a href="https://g.co/kgs/ZonduH">Sriramajeyam Sugumaran</a>, A full stack web developer from Chennai, India. Currently living in London, United Kingdom. </p>
            <p>I've been doing web development since 2007. My current interests in the web technologies are Javascript, NodeJS, VueJS, Grafana, Performance Optimization, SRE, Azure & Devops. If you are interested to know about the tools I am using day to day, visit my <a href="/uses">uses</a> page</p>
        </div>
        <div class="aboutright">
            <img src="img/sriram.png" style="border-radius:10%;" width="183px" height="220px"/>
        </div>
    </div>
  </div>
</template>

<style>
#homebanner .about {
    display: flex;
    flex-direction: row;
}
.aboutleft {
    min-height: 220px;
    flex-grow: 1;
}
.aboutright {
    min-width: 230px;
    padding: 5px
}
@media only screen and (max-width: 600px) {
  .aboutright {
        min-width: 0px !important;
        max-width: 0px !important;
        display: none;
 }
}
</style>