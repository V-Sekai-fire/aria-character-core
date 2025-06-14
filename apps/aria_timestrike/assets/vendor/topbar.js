// Simple topbar implementation for Phoenix LiveView
const topbar = {
  config: function(options) {
    this.options = options || {};
  },
  
  show: function(duration) {
    // Simple progress bar at top of page
    let bar = document.getElementById('topbar');
    if (!bar) {
      bar = document.createElement('div');
      bar.id = 'topbar';
      bar.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 0%;
        height: 3px;
        background: #29d;
        transition: width ${duration || 300}ms ease;
        z-index: 9999;
      `;
      document.body.appendChild(bar);
    }
    
    bar.style.width = '30%';
    
    setTimeout(() => {
      bar.style.width = '70%';
    }, 100);
  },
  
  hide: function() {
    const bar = document.getElementById('topbar');
    if (bar) {
      bar.style.width = '100%';
      setTimeout(() => {
        bar.style.opacity = '0';
        setTimeout(() => {
          if (bar.parentNode) {
            bar.parentNode.removeChild(bar);
          }
        }, 200);
      }, 100);
    }
  }
};

export default topbar;
