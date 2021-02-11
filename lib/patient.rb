class Patient
  attr_reader :pin, :surname, :name1, :name2, :dr

  def initialize(pin:, surname:, name1:, name2:, dr:)
    @pin = pin
    @surname = surname
    @name1 = name1
    @name2 = name2
    @dr = dr
    @checked = false
  end

  def check(text)
    score = 0
    pass_score = 3
    score += 2 if text.match?(@surname)
    score += 1 if text.match?(@name1)
    score += 1 if text.match?(@name2)
    score += 1 if text.match?(@dr)
    @checked = score >= pass_score
  end

  def found?
    (@pin + @surname + @name1 + @name2 + @dr).length > 0
  end
end