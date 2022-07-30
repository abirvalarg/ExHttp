defmodule ExHttp.Http.Cookie do
  @moduledoc """
  Represents an HTTP cookie
  """

  defstruct name: "", val: "", same_site: nil, max_age: nil, http_only: true

  @type t :: %ExHttp.Http.Cookie{
    name: String.t,
    val: String.t,
    same_site: String.t | nil,
    max_age: integer | nil,
  }

  @spec new(String.t, String.t) :: t
  @doc """
  Convenience function to create a new default cookie
  """
  def new name, val do
    %__MODULE__{
      name: name,
      val: val
    }
  end
end

defimpl String.Chars, for: ExHttp.Http.Cookie do
  def to_string self do
    cookie = "#{self.name}=#{self.val}"
    cookie = if self.same_site do
      cookie <> "; Same-Site=" <> self.same_site
    else
      cookie
    end

    cookie = if self.max_age do
      cookie <> "; Max-Age=" <> self.max_age
    else
      cookie
    end

    cookie
  end
end
