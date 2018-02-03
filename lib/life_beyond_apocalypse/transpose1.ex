defmodule Transpose1 do

  def transpose(m) do
    attach_row(m, [])
  end
  
  @doc """
  Given a matrix and a result, make the first row into a column,
  attach it to the result, and then recursively attach the
  remaining rows to that new result.
  
  When the original matrix has no rows remaining, the result
  matrix is complete, but each row needs to be reversed. 
  """
  def attach_row([], result) do
    reverse_rows(result, [])
  end

  def attach_row(row_list, result) do
    [first_row | other_rows] = row_list
    new_result = make_column(first_row, result)
    attach_row(other_rows, new_result)
  end
                                         
  @doc """
  Make a row into a column. There are three clauses:
  
  When there are no more entries in the row, the column you are
  making is complete.
  
  Make the row into a column when the result matrix is empty.
  Create the first item as a singleton list. Follow it with
  the result of making the remaining entries in the column.
  
  Make a row into a column when the result matrix is not empty.
  Do this by adding the first item at the beginning of the first row of
  the result. That list is followed by the result of making the remaining entries in the column.
  """
  def make_column([], result) do # my job here is done
    result
  end
  
  def make_column(row, []) do
    [first_item | other_items] = row
    [[first_item] | make_column(other_items, [])]
  end
  
  def make_column(row, result) do
    [first_item | other_items] = row
    [first_row | other_rows] = result
    [[first_item | first_row] | make_column(other_items, other_rows)]
  end

  @doc """
  Reverse the order of items in each row of a matrix. This constructs
  a new matrix whose rows are in reverse order, so you need to reverse
  the final result.
  """
  def reverse_rows([], result) do
    Enum.reverse(result)
  end

  def reverse_rows(rows, result) do
    [first | others] = rows
    reverse_rows(others, [Enum.reverse(first) | result])
  end
  
end
