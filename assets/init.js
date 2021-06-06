(function () {
    var amis = amisRequire('amis/embed');
    var labelOption = {
        show: true,
        position: 'insideBottom',
        distance: 5,
        align: 'left',
        verticalAlign: 'middle',
        rotate: 90,
        formatter: '{c}',
        fontSize: 9,
        rich: {
            name: {
            }
        }
    };
    var amisJSON = {
        "type": "app",
        "brandName": "🌾Beam🌾",
        "data": {
            "updateDate": updateDate
        },
        //"logo": "./erlang.svg",
        header: {
            type: 'tpl',
            inline: false,
            className: 'w-full',
            tpl: '<div class="flex justify-between"><div><img src="https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fbeam-trending.github.io&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false"/></div><div>${updateDate}</div></div>'
        },
        "pages": [
            {
                "children": top_nav
            },
            {
                "label": "🌾",
                "url": "index.html",
                "isDefaultPage": true,
                "schema": {
                    "type": "page",
                    "body": [
                        {
                            "type": "chart",
                            "config": {
                                "tooltip": {
                                    "trigger": "axis",
                                    "position": function (pt) {
                                        return [pt[0], '10%'];
                                    }
                                },
                                "title": {
                                    "left": "center",
                                    "text": "⭐️",
                                },
                                "toolbox": {
                                    show: true,
                                    orient: 'vertical',
                                    left: 'right',
                                    top: 'center',
                                    "feature": {
                                        "restore": {},
                                        "saveAsImage": {}
                                    }
                                },
                                "xAxis": {
                                    "type": "time",
                                    "right": "10%",
                                    "left": "10%",
                                    "boundaryGap": false
                                },
                                "yAxis": {
                                    "type": "value",
                                    "boundaryGap": false
                                },
                                "dataZoom": [{
                                    "type": "inside",
                                    "rangeMode": ['value', 'percent'],
                                    "startValue": "2011-01-02",
                                    "end": 100
                                },
                                {
                                    "start": 0,
                                    "end": 5
                                }
                                ],
                                "series": [
                                    {
                                        "name": "erlang",
                                        "type": "line",
                                        "smooth": true,
                                        "symbol": "none",
                                        "areaStyle": { "color": "blue" },
                                        "data": erlang_otp_star
                                    },
                                    {
                                        "name": "elixir",
                                        "type": "line",
                                        "smooth": true,
                                        "symbol": "none",
                                        "areaStyle": {},
                                        "data": elixir_lang_elixir_star
                                    }
                                ]
                            }
                        },
                        {
                            "type": "chart",
                            "config":
                            {
                                "title": {
                                    "top": 1,
                                    "left": "center",
                                    "text": "Commits"
                                },
                                "tooltip": { "position": "top" },
                                "toolbox": {
                                    "show": true,
                                    "orient": 'vertical',
                                    "left": 'right',
                                    "top": 'center',
                                    "feature": {
                                        "restore": {},
                                        "saveAsImage": {}
                                    }
                                },
                                "visualMap": {
                                    "pieces": [
                                        { "min": 10 },
                                        { "min": 5, "max": 10 },
                                        { "min": 4, "max": 5 },
                                        { "min": 3, "max": 4 },
                                        { "min": 2, "max": 3 },
                                        { "min": 1, "max": 2 },
                                        { "max": 1 }
                                    ],
                                    "type": "piecewise",
                                    "orient": "horizontal",
                                    "left": "center",
                                    "top": 65,
                                    "inRange": {
                                        "color": ["white", "green"] //From smaller to bigger value ->
                                    }
                                },
                                "calendar": [{
                                    "top": 100,
                                    "right": "10%",
                                    "left": "10%",
                                    "cellSize": ["auto", 13],
                                    "range": erlang_otp_commit_range,
                                    "itemStyle": {
                                        "borderWidth": 0.5
                                    },
                                    "yearLabel": { "formatter": "Erlang" }
                                },
                                {
                                    "top": 210,
                                    "right": "10%",
                                    "left": "10%",
                                    "cellSize": ["auto", 13],
                                    "range": elixir_lang_elixir_commit_range,
                                    "itemStyle": {
                                        "borderWidth": 0.5
                                    },
                                    "yearLabel": { "formatter": "Elixir" }
                                }],
                                "series": [{
                                    "type": "heatmap",
                                    "coordinateSystem": "calendar",
                                    "calendarIndex": 0,
                                    "data": erlang_otp_year_commit
                                },
                                {
                                    "type": "heatmap",
                                    "coordinateSystem": "calendar",
                                    "calendarIndex": 1,
                                    "data": elixir_lang_elixir_year_commit
                                }]
                            }
                        },
                        {
                            type: 'chart',
                            config: {
                                tooltip: {
                                    trigger: 'axis',
                                    axisPointer: {
                                        type: 'shadow'
                                    }
                                },
                                legend: {
                                    data: ['Erlang', 'Elixir']
                                },
                                toolbox: {
                                    show: true,
                                    orient: 'vertical',
                                    left: 'right',
                                    top: 'center',
                                    feature: {
                                        mark: { show: true },
                                        dataView: { show: true, readOnly: false },
                                        magicType: { show: true, type: ['line', 'bar', 'stack', 'tiled'] },
                                        restore: { show: true },
                                        saveAsImage: { show: true }
                                    }
                                },
                                xAxis: [
                                    {
                                        type: 'category',
                                        axisTick: { show: false },
                                        right: "10%",
                                        left: "10%",
                                        data: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31', '32', '33', '34', '35', '36', '37', '38', '39', '40', '41', '42', '43', '44', '45', '46', '47', '48', '49', '50', '51', '52']
                                    }
                                ],
                                yAxis: [
                                    {
                                        type: 'value'
                                    }
                                ],
                                series: [
                                    {
                                        name: 'Erlang',
                                        type: 'line',
                                        barGap: 0,
                                        label: labelOption,
                                        emphasis: {
                                            focus: 'series'
                                        },
                                        data: erlang_otp_week_commit
                                    },
                                    {
                                        name: 'Elixir',
                                        type: 'line',
                                        label: labelOption,
                                        emphasis: {
                                            focus: 'series'
                                        },
                                        data: elixir_lang_elixir_week_commit
                                    },
                                ]
                            }
                        },
                        {
                            type: "chart",
                            config: {
                                tooltip: {
                                    trigger: 'item',
                                    triggerOn: 'mousemove',
                                },
                                toolbox: {
                                    show: true,
                                    orient: 'vertical',
                                    left: 'right',
                                    top: 'center',
                                    feature: {
                                        restore: {},
                                        saveAsImage: {}
                                    }
                                },
                                series: [
                                    {
                                        type: 'tree',
                                        data: [release_tree],
                                        left: '10%',
                                        right: '10%',
                                        top: '11%',
                                        bottom: '48%',
                                        symbol: 'emptyCircle',
                                        orient: 'TB',
                                        expandAndCollapse: true,
                                        label: {
                                            position: 'top',
                                            rotate: -90,
                                            verticalAlign: 'middle',
                                            align: 'right'
                                        },
                                        leaves: {
                                            label: {
                                                position: 'top',
                                                rotate: -90,
                                                verticalAlign: 'middle',
                                                align: 'left'
                                            }
                                        },
                                        emphasis: {
                                            focus: 'descendant'
                                        },
                                        animationDurationUpdate: 750
                                    }
                                ]
                            }
                        },
                        {
                            "type": "chart",
                            "config": {
                                "tooltip": {
                                    "trigger": "axis",
                                    "position": function (pt) {
                                        return [pt[0], '10%'];
                                    }
                                },
                                "title": {
                                    "left": "center",
                                    "text": "Line",
                                },
                                "toolbox": {
                                    show: true,
                                    orient: 'vertical',
                                    left: 'right',
                                    top: 'center',
                                    "feature": {
                                        "restore": {},
                                        "saveAsImage": {}
                                    }
                                },
                                "xAxis": {
                                    "type": "time",
                                    "right": "10%",
                                    "left": "10%",
                                    "boundaryGap": false
                                },
                                "yAxis": {
                                    "type": "value",
                                    "boundaryGap": false
                                },
                                "dataZoom": [{
                                    "type": "inside",
                                    "rangeMode": ['value', 'percent'],
                                    "startValue": "2020-01-01",
                                    "end": 100
                                },
                                {
                                    "start": 0,
                                    "end": 5
                                }
                                ],
                                "series": [
                                    {
                                        "name": "erlang+",
                                        "type": "line",
                                        "smooth": true,
                                        "symbol": "none",
                                        "lineStyle": { "color": "green" },
                                        "areaStyle": {},
                                        "data": erlang_otp_add_code
                                    },
                                    {
                                        "name": "elixir+",
                                        "type": "line",
                                        "smooth": true,
                                        "symbol": "none",
                                        "lineStyle": { "color": "purple" },
                                        "areaStyle": {},
                                        "data": elixir_lang_elixir_add_code
                                    },
                                    {
                                        "name": "erlang-",
                                        "type": "line",
                                        "smooth": true,
                                        "symbol": "none",
                                        "lineStyle": { "color": "red" },
                                        "areaStyle": {},
                                        "data": erlang_otp_del_code
                                    },
                                    {
                                        "name": "elixir-",
                                        "type": "line",
                                        "smooth": true,
                                        "symbol": "none",
                                        "lineStyle": { "color": "grey" },
                                        "areaStyle": {},
                                        "data": elixir_lang_elixir_del_code
                                    }
                                ]
                            },
                            "toolbar": [
                            ]
                        },
                        {
                            "type": "wrapper",
                            "body": erlang_otp_contributors,
                        },
                        { "type": "divider" },
                        {
                            "type": "wrapper",
                            "body": elixir_lang_elixir_contributors,
                        },
                    ]
                }
            }]
    };
    var amisScoped = amis.embed('#root', amisJSON, { locale: 'en-US' });
})();