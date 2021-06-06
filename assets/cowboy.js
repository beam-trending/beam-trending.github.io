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
                            "name": "cowboy",
                            "type": "line",
                            "smooth": true,
                            "symbol": "none",
                            "areaStyle": { "color": "blue" },
                            "data": ninenines_cowboy_star
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
                        "top": 60,
                        "inRange": {
                            "color": ["white", "green"] //From smaller to bigger value ->
                        }
                    },
                    "calendar": [{
                        "top": 100,
                        "right": "10%",
                        "left": "10%",
                        "cellSize": ["auto", 20],
                        "range": ninenines_cowboy_commit_range,
                        "itemStyle": {
                            "borderWidth": 0.5
                        },
                        "yearLabel": { "formatter": "Cowboy" }
                    }
                    ],
                    "series": [{
                        "type": "heatmap",
                        "coordinateSystem": "calendar",
                        "data": ninenines_cowboy_year_commit
                    }
                    ]
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
                        data: ['Cowboy']
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
                            name: 'cowboy',
                            type: 'line',
                            barGap: 0,
                            label: labelOption,
                            emphasis: {
                                focus: 'series'
                            },
                            data: ninenines_cowboy_week_commit
                        }                        
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
                            "name": "cowboy+",
                            "type": "line",
                            "smooth": true,
                            "symbol": "none",
                            "lineStyle": { "color": "green" },
                            "areaStyle": {},
                            "data": ninenines_cowboy_add_code
                        },                        
                        {
                            "name": "cowboy-",
                            "type": "line",
                            "smooth": true,
                            "symbol": "none",
                            "lineStyle": { "color": "red" },
                            "areaStyle": {},
                            "data": ninenines_cowboy_del_code
                        },                                            
                    ]
                },
                "toolbar": [
                ]
            },
            {
                "type": "wrapper",
                "body": ninenines_cowboy_contributors,
                "className": "b",
            }
        ]
    };
    var amisScoped = amis.embed('#root', amisJSON);
})();