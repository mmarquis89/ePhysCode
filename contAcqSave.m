function contAcqSave(src, event)
    assignin('base', 'newX', event.Data);
    evalin('base','x = [x;newX];');
end