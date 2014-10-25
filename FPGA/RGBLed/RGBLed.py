import wx
import wx.lib.pubsub
from xstools.xsdutio import *

class MyTimer(wx.Timer):

    def __init__(self, *args, **kwargs):
        super(MyTimer, self).__init__(*args, **kwargs)
        self.Start(milliseconds=500, oneShot=False)
        
    def Notify(self):
        wx.lib.pubsub.Publisher().sendMessage("Blink")

class MyForm(wx.Frame):

    def __init__(self):
        wx.Frame.__init__(self, None, wx.ID_ANY, "RGB PWM Demo")
        panel = wx.Panel(self, wx.ID_ANY)
        
        self.num_colors = 3
        self.active_color = 0
        self.timer = MyTimer()

        self.ledColor = []
        for i in range(0, self.num_colors):
            self.ledColor.append(wx.ColourPickerCtrl(parent=panel, style=wx.CLRP_SHOW_LABEL))

        wx.lib.pubsub.Publisher().subscribe(self.onBlink,"Blink")
        
        # put the color picker controls in a sizer
        sizer = wx.BoxSizer(wx.VERTICAL)
        for i in range(0, self.num_colors):
            sizer.Add(self.ledColor[i], 0, wx.ALL | wx.CENTER, 5)
        panel.SetSizer(sizer)
        
    def onBlink(self, msg):
        self.active_color += 1
        self.active_color %= self.num_colors
        color = self.ledColor[self.active_color]
        r = color.GetColour().Red()
        g = color.GetColour().Green()
        b = color.GetColour().Blue()
        pwm.write(b, g, r)
        


if __name__ == "__main__":
    XSUSB_ID = 0
    PWM_ID = 255
    pwm = XsDutIo(xsusb_id=XSUSB_ID, module_id=PWM_ID, dut_output_widths=[1], dut_input_widths=[8, 8, 8])

    app = wx.App(False)
    frame = MyForm()
    frame.Show()
    app.MainLoop()
