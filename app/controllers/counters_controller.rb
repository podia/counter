# A stupid little controller showing how easy you can build generic "counter" functionality
# when they're represented as a model
class CountersController < ApplicationController
  # Reset a counter to 0
  def destroy
    Counter::Value.find(params[:id]).reset!

    redirect_back fallback_location: "/"
  end

  # Recalculate a counter
  def update
    Counter::Value.find(params[:id]).recalc!

    redirect_back fallback_location: "/"
  end
end
