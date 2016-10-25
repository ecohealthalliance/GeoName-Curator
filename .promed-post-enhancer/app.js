import 'd3';
import 'event-drops';
import 'event-drops/dist/eventDrops.css';
import './styles.css';
const EIDR_CONNECT_URL = "https://eidr-connect.eha.io";

const FONT_SIZE = 16; // in pixels
const TOOLTIP_WIDTH = 30; // in rem
const showTooltip = (article)=> {
  d3.select('body').selectAll('.tooltip').remove();

  const tooltip = d3.select('body')
  .append('div')
  .attr('class', 'tooltip')
  .style('opacity', 0); // hide it by default

  // show the tooltip with a small animation
  tooltip.transition()
  .duration(200)
  .each('start', function start(){
    d3.select(this).style('block');
  })
  .style('opacity', 1);

  const rightOrLeftLimit = FONT_SIZE * TOOLTIP_WIDTH;
  const direction = d3.event.pageX > rightOrLeftLimit ? 'right' : 'left';

  const ARROW_MARGIN = 1.65;
  const ARROW_WIDTH = FONT_SIZE;
  const left = direction === 'right' ?
    d3.event.pageX - rightOrLeftLimit :
    d3.event.pageX - ARROW_MARGIN * FONT_SIZE - ARROW_WIDTH / 2;

  tooltip.html(`
    <div class="marker">
      <div class="content">
        <p>
          <a href="${article.url}" class="author">${article.url}</a>
        </p>
        <p>
          Published on <span class="date">${(new Date(article.publishDate)).toLocaleString()}</span>
        </p>
      </div>
    </div>
  `)
  .classed(direction, true)
  .style({
    left: `${left}px`,
    top: (d3.event.pageY + 16) + 'px',
  });
};

const hideTooltip = () => {
  d3.select('.tooltip').transition()
  .duration(200)
  .each('end', function end(){
    this.remove();
  })
  .style('opacity', 0);
};

var enhancing = false;
if(window.obs) window.obs.disconnect();
const enhance = (target)=>{
  if(enhancing) return;
  enhancing  = true;
  let postIdMatch = document.querySelector(".printable a").onclick.toString().match(/post\/(\d+)/);
  if(!postIdMatch) return enhancing=false;
  let postId = window.__debugPostId || postIdMatch[1];
  let url = "http://promedmail.org/post/" + postId;
  let eidrConnectUrl = window.__debugEidrConnectUrl || EIDR_CONNECT_URL;
  $.getJSON(eidrConnectUrl + "/api/events-with-source", {
    url: url
  }, (events)=>{
    if(!events || events.length === 0) return enhancing=false;
    $(target)
    .find(".printable")
    .after(`
      <p>EIDR-Connect Events:&nbsp;
        ${events.map((event)=>{
          return `<a href="https://eidr-connect.eha.io/user-event/${event._id}">
            ${event.eventName}
          </a>`;
        }).join(", ")}
      </p>
      <div id="plotContainer">
        <p class="timeline-title">Event timeline:</p>
        <div class="eidr-chart"></div>
      </div>
    `);
    
    var minPubDate = new Date();
    events.forEach((event)=>{
      event.articles.forEach((article)=>{
        if(!article.publishDate) return;
        let publishDate = new Date(article.publishDate);
        if(publishDate < minPubDate){
          minPubDate = publishDate;
        }
      });
    });
    const chart = d3.chart.eventDrops()
    //Start a day before the first date
    .start(new Date(minPubDate.getTime() - 3600000 * 24))
    .end(new Date(Date.now() + 3600000 * 24))
    .margin({
      top: 50, bottom: 0, left: 0, right: 0
    })
    .labelsWidth(0)
    .eventColor((d, i)=>{
      return d.url === url ? '#ff0000' : '#0d73bb';
    })
    .date(a => new Date(a.publishDate))
    .click(showTooltip);
    
    $(document).click((evt)=>{
      if(evt.target.matches(".drop")) return;
      if(!$(evt.target).closest('.tooltip').length) hideTooltip();
    });

    const element = d3.select('.eidr-chart').datum(events.map((event)=>({
      name: event.eventName,
      data: event.articles.filter(a=>a.publishDate)
    })));

    chart(element);

    // A timeout is used for debouncing
    setTimeout(()=>{
      enhancing = false;
    }, 100);
  });
};
window.obs = new MutationObserver((mutations)=>{
  enhance(mutations[0].target);
});
window.obs.observe(document.querySelector("#preview"), { childList:true });
enhance(document.querySelector("#preview"));
