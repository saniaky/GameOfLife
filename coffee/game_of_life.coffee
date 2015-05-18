# Рано или поздно игра зациклится (останутся только фигуры-осцилляторы),
# т.е. начиная с какого-то момента каждые n ходов будет одна и та же картинка.
# Требуется найти n.
class GameOfLife
    numberOfRows: 200
    numberOfColumns: 200
    cellSize: 10
    refreshInterval: 10
    currentGeneration: null
    canvas: null
    canvasContext: null
    pause: true
    history: []
    history_size: 5000
    redrawPoints: []

    constructor: ->
        @createCanvas()
        @resizeCanvas()
        @createContext()
        @initGeneration()
        @drawField()
        @initButtons()
        opts = {
          distance : @cellSize,
          lineWidth : 1.0,
          gridColor  : 'rgb(210, 210, 210)',
          caption : false
        }
        new Grid(opts).draw(@canvasContext);

    initButtons: ->
        $("#play").click (event) => @playGame()
        $("#pause").click (event) => @pauseGame()
        $("#clear").click (event) => @clearGame()
        $("#canvasField").mousedown (event) =>
            point = 
                column: Math.floor ((event.pageX - $("#canvasField").offset().left) / @cellSize)
                row:    Math.floor ((event.pageY - $("#canvasField").offset().top) / @cellSize)
            @currentGeneration[point.row][point.column].isAlive = !@currentGeneration[point.row][point.column].isAlive
            @redrawPoints.push point
            @tick()

    playGame: ->
        @pause = false
        @tick()
        $("#play").attr disabled: "disabled"
        $("#pause").removeAttr "disabled"

    pauseGame: ->
        @pause = true
        $("#pause").attr disabled: "disabled"
        $("#play").removeAttr "disabled"

    clearGame: ->
        @pauseGame()
        @initGeneration()
        @drawField()
        @history = []
        
    createCanvas: ->
        @canvas = document.createElement 'canvas'
        @canvas.setAttribute("id", "canvasField");
        document.getElementById('game').appendChild @canvas

    createContext: ->
        @canvasContext = @canvas.getContext '2d'
    
    initGeneration: ->
        @currentGeneration = []
        for row in [0..@numberOfRows]
            @currentGeneration[row] = []
            for column in [0..@numberOfColumns]
                @currentGeneration[row][column] = @createCell row, column

    createCell: (row, column) ->
        isAlive: false
        row: row
        column: column

    resizeCanvas: ->
        @canvas.width = @cellSize * @numberOfColumns
        @canvas.height = @cellSize * @numberOfRows

    tick: =>
        @updateField()
        if @pause then return
        @calculateNextGeneration()
        setTimeout @tick, @refreshInterval
  
    drawField: ->
        for row in [0..@numberOfRows]
            for column in [0..@numberOfColumns]
                @drawCell @currentGeneration[row][column]
    
    updateField: ->
        p = @redrawPoints.pop()
        while !!p
            @drawCell @currentGeneration[p.row][p.column]
            p = @redrawPoints.pop()

    drawCell: (cell) ->
        x = cell.column * @cellSize
        y = cell.row * @cellSize
        if cell.isAlive
            fill = 'rgb(100, 200, 70)'
        else
            fill = 'rgb(250, 250, 250)'
        @canvasContext.fillStyle = fill
        @canvasContext.fillRect x+1, y+1, @cellSize-1, @cellSize-1

    updateCellState: (cell) ->
        newCell =
            row: cell.row
            column: cell.column
            isAlive: cell.isAlive
        sum = @countAliveCells cell
        if cell.isAlive or sum is 3
            newCell.isAlive = 1 < sum < 4
        newCell

    countAliveCells: (cell) ->
        p = []
        p[1] = {row: cell.row - 1, column: cell.column - 1}
        p[2] = {row: cell.row - 1, column: cell.column}
        p[3] = {row: cell.row - 1, column: cell.column + 1}
        p[4] = {row: cell.row, column: cell.column - 1}
        p[5] = {row: cell.row, column: cell.column + 1}
        p[6] = {row: cell.row + 1, column: cell.column - 1}
        p[7] = {row: cell.row + 1, column: cell.column}
        p[8] = {row: cell.row + 1, column: cell.column + 1}
        
        if cell.row - 1 < 0
            p[1].row = p[2].row = p[3].row = @numberOfRows
        if cell.column - 1 < 0
            p[1].column = p[4].column = p[6].column = @numberOfColumns
        if cell.row + 1 > @numberOfRows
            p[6].row = p[7].row = p[8].row = 0
        if cell.column + 1 > @numberOfColumns
            p[3].column = p[5].column = p[8].column = 0

        count = 0
        for index in [1..8]
            if @currentGeneration[p[index].row][p[index].column].isAlive
                count++
        count

    isCycleDetected: ->
        return @getCurrentSha() in @history

    calculateNextGeneration: ->
        if @isCycleDetected()
            alert 'Cycle is found (' + @history.length + ' generations)'
            console.log @getCurrentSha()
            @pauseGame()
            return

        @history.push @getCurrentSha()
        @history.shift if @history.length > @history_size

        nextGeneration = []
        for row in [0..@numberOfRows]
            nextGeneration[row] = []
            for column in [0..@numberOfColumns]
                cell = @updateCellState @currentGeneration[row][column]
                nextGeneration[row][column] = cell
                if cell.isAlive != @currentGeneration[row][column].isAlive
                    point = { row: row, column: column }
                    @redrawPoints.push point
        @currentGeneration = nextGeneration

    getCurrentSha: ->
        buffer = ''
        for row in [0..@numberOfRows]
            for column in [0..@numberOfColumns]
                buffer += @currentGeneration[row][column].isAlive
        hash = CryptoJS.SHA1(buffer).toString(CryptoJS.enc.Base64)
        
