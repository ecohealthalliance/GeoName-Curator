export default (svg, scales, configuration) => function dropsSelector(data) {
    const dropLines = svg.selectAll('.drop-line').data(data);

    dropLines.enter()
        .append('g')
        .classed('drop-line', true)
        .attr('transform', (d, idx) => `translate(10, ${scales.y(idx)})`)
        .attr('fill', configuration.eventLineColor);

    dropLines.each(function dropLineDraw(drop) {
        const drops = d3.select(this).selectAll('.drop').data(drop.data);

        drops.attr('cx', d => scales.x(configuration.date(d)));

        const circle = drops.enter()
            .append('circle')
            .classed('drop', true)
            .attr('r', 5)
            .attr('cx', d => scales.x(configuration.date(d)))
            .attr('cy', configuration.lineHeight / 2)
            .attr('fill', configuration.eventColor);

        circle.on('click', configuration.click);
        circle.on('mouseover', configuration.mouseover);

        circle.on('mouseout', configuration.mouseout);

        // unregister previous event handlers to prevent from memory leaks
        drops.exit()
            .on('click', null)
            .on('mouseout', null)
            .on('mouseover', null)
            .remove();
    });

    dropLines.exit().remove();
};
