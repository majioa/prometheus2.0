let changeHref = (e) => {
   let index = e.target.options.selectedIndex,
       url = e.target.options[index].getAttribute('value')

   document.querySelectorAll('a.download').forEach((a) => {
      let href = a.getAttribute('data-path')

      a.setAttribute('href', url + href)
   })
}

let toggleListItem = (e) => {
   e.target.parentNode.classList.toggle("open");
}

let setup_ga = (parent) => {
   let ga = document.createElement('script')

   ga.type = 'text/javascript'; ga.async = true
   ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js'
   parent.appendChild(ga)
}

let setup_gauges = (parent) => {
   let t = document.createElement('script')

   t.type  = 'text/javascript'
   t.async = true
   t.id    = 'gauges-tracker'
   t.setAttribute('data-site-id', '4f0625f8613f5d5abc000005')
   t.src = '//secure.gaug.es/track.js'
   parent.appendChild(t)
}

let _gaq = []
// <span id="siteseal"><script type="text/javascript" src="https://seal.godaddy.com/getSeal?sealID=ieZLMPwOodpPSCAR5I21qWYk5RmWMlaj0LAmqwapj0dQdM3cioq8Lt6MbX6g"></script></span>

document.addEventListener('DOMContentLoaded', () => {
   let url = document.querySelector('.mirror-url'),
       groupTitles = document.querySelectorAll('.group-title')

   if (url) {
      url.addEventListener('change', changeHref)
   }

   groupTitles.forEach((gT) => {
      gT.addEventListener('click', toggleListItem)
   })

   _gaq.push(['_setAccount', 'UA-37366896-1'])
   _gaq.push(['_trackPageview'])

   let parent = document.querySelector('head')
   setup_ga(parent)
   setup_gauges(parent)
})
