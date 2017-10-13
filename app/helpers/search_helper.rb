module SearchHelper
  def annotation_url(id, num = 0)
    "urn:pmp:#{id}_#{num}"
  end

  def manifest_canvas_on_xywh(parent_path, id, xywh)
    "#{parent_path}/manifest/canvas/#{id}#xywh=#{xywh}"
  end
end
