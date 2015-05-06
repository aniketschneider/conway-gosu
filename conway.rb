require 'gosu'
require 'hasu'

module ZOrder
  World, Cells, UI = *0..2
end

class Population
  CELL_COLOR = Gosu::Color::BLACK


  def initialize(x_size, y_size)
    @x_size = x_size
    @y_size = y_size
    @grid = new_grid(x_size, y_size)
  end

  def each_point
    @grid.each_with_index do |col, x_val|
      col.each_with_index do |cell, y_val|
        yield x_val, y_val, cell
      end
    end
  end

  def draw(window)
    each_point do |col, row, cell|
      if cell != 0
        draw_cell(window, col * 10, row * 10)
      end
    end
  end

  def draw_cell(window, x, y)
    window.draw_quad(x+1, y+1, CELL_COLOR,
                     x+9, y+1, CELL_COLOR,
                     x+9, y+9, CELL_COLOR,
                     x+1, y+9, CELL_COLOR,
                     ZOrder::Cells)
  end

  def toggle(col, row)
    if @grid[col][row] == 0
      @grid[col][row] = 1
    else
      @grid[col][row] = 0
    end
  end

  def new_grid(cols, rows)
    grid = []
    cols.times { grid.push Array.new(rows, 0) }
    grid
  end

  def iterate
    next_gen = new_grid(@x_size, @y_size)
    each_point do |col, row, cell|
      if cell == 1
        next_gen[col-1][row-1] += 1 unless col == 0 || row == 0
        next_gen[col-1][row] += 1 unless col == 0
        next_gen[col-1][row+1] += 1 unless col == 0 || row == @y_size - 1
        next_gen[col][row-1] += 1 unless row == 0
        next_gen[col][row+1] += 1 unless row == @y_size - 1
        next_gen[col+1][row-1] += 1 unless col == @x_size - 1 || row == 0
        next_gen[col+1][row] += 1 unless col == @x_size - 1
        next_gen[col+1][row+1] += 1 unless col == @x_size - 1 || row == @y_size - 1
      end
    end

    next_gen.each_with_index do |col, x_val|
      col.each_with_index do |result, y_val|
        case
        when result < 2
          @grid[x_val][y_val] = 0
        when result == 2
          @grid[x_val][y_val] = 1 if @grid[x_val][y_val] == 1
        when result == 3
          @grid[x_val][y_val] = 1
        when result > 3
          @grid[x_val][y_val] = 0
        end
      end
    end
  end
end

class GameWindow < Hasu::Window
  MAX_X = 640
  MAX_Y = 480

  def initialize
    super MAX_X, MAX_Y, false
  end

  def reset
    self.caption = "Conway's Game of Gosu"
    @population = Population.new(MAX_X / 10, MAX_Y / 10)
    @state = :paused
    @last_update = 0
  end

  def update
    if @state == :running && Gosu::milliseconds - @last_update > 200
      @last_update = Gosu::milliseconds
      @population.iterate
      #@state = :paused
    end
  end

  def draw
    draw_quad(0,     0,    Gosu::Color::GRAY,
              0,     MAX_Y,Gosu::Color::WHITE,
              MAX_X, MAX_Y,Gosu::Color::WHITE,
              MAX_X, 0,    Gosu::Color::WHITE,
              ZOrder::World)
    @population.draw(self)

    draw_cursor

  end

  def draw_cursor
    draw_triangle(mouse_x, mouse_y, Gosu::Color::RED,
                  mouse_x, mouse_y+13, Gosu::Color::RED,
                  mouse_x+10, mouse_y+10, Gosu::Color::RED,
                  ZOrder::UI)
  end

  def toggle_pause
    case @state
    when :paused
      @state = :running
    when :running
      @state = :paused
    end
  end

  def button_down(id)
    case id
    when Gosu::KbEscape
      close
    when Gosu::MsLeft
      @population.toggle(mouse_x / 10, mouse_y / 10)
    when Gosu::KbSpace
      toggle_pause
    end
  end
end

GameWindow.run

